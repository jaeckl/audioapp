#include "audioapp/LivePerformance.hpp"

#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/SamplerFilter.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

void LivePerformanceMixer::reset() noexcept {
    allNotesOff();
    sampleClock_.store(0, std::memory_order_release);
}

void LivePerformanceMixer::advanceSampleClock(int numFrames) noexcept {
    if (numFrames <= 0) {
        return;
    }
    sampleClock_.fetch_add(static_cast<uint64_t>(numFrames), std::memory_order_relaxed);
}

uint64_t LivePerformanceMixer::sampleClock() const noexcept {
    return sampleClock_.load(std::memory_order_acquire);
}

void LivePerformanceMixer::releaseVoice(LiveVoiceSlot& voice, uint64_t now) noexcept {
    if (voice.active.load(std::memory_order_acquire) == 0) {
        return;
    }
    if (!voice.releasing) {
        voice.releasing = true;
        voice.releaseSample = now;
    }
}

int LivePerformanceMixer::noteOn(const LiveInstrumentSnapshot& instrument, int pitch, float velocity) noexcept {
    if (instrument.kind == LiveInstrumentKind::None) {
        return -1;
    }
    const uint64_t now = sampleClock();
    for (auto& voice : voices_) {
        if (voice.active.load(std::memory_order_acquire) != 0 && voice.pitch == pitch && !voice.releasing) {
            releaseVoice(voice, now);
        }
    }

    for (int i = 0; i < kLiveMaxVoices; ++i) {
        auto& voice = voices_[i];
        if (voice.active.load(std::memory_order_acquire) != 0) {
            continue;
        }
        voice.instrument = instrument;
        voice.pitch = pitch;
        voice.velocity = std::clamp(velocity, 1.0f, 127.0f);
        voice.startSample = now;
        voice.releaseSample = 0;
        voice.releasing = false;
        voice.oscillatorPhase = 0.0f;
        voice.filterState = BiquadState{};
        voice.active.store(1, std::memory_order_release);
        return i;
    }

    auto& steal = voices_[0];
    steal.active.store(0, std::memory_order_release);
    steal.instrument = instrument;
    steal.pitch = pitch;
    steal.velocity = std::clamp(velocity, 1.0f, 127.0f);
    steal.startSample = now;
    steal.releaseSample = 0;
    steal.releasing = false;
    steal.oscillatorPhase = 0.0f;
    steal.filterState = BiquadState{};
    steal.active.store(1, std::memory_order_release);
    return 0;
}

void LivePerformanceMixer::noteOff(int pitch) noexcept {
    const uint64_t now = sampleClock();
    for (auto& voice : voices_) {
        if (voice.active.load(std::memory_order_acquire) == 0) {
            continue;
        }
        if (voice.pitch == pitch && !voice.releasing) {
            releaseVoice(voice, now);
        }
    }
}

void LivePerformanceMixer::allNotesOff() noexcept {
    const uint64_t now = sampleClock();
    for (auto& voice : voices_) {
        releaseVoice(voice, now);
    }
}

void LivePerformanceMixer::readMix(float* monoOut, int numFrames, double sampleRate) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || sampleRate <= 0.0) {
        return;
    }

    const uint64_t blockStart = sampleClock();

    for (int frame = 0; frame < numFrames; ++frame) {
        const uint64_t sampleIndex = blockStart + static_cast<uint64_t>(frame);
        float mix = 0.0f;

        for (auto& voice : voices_) {
            if (voice.active.load(std::memory_order_acquire) == 0) {
                continue;
            }

            const auto& inst = voice.instrument;
            const double elapsedSec =
                static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
            if (elapsedSec < 0.0) {
                continue;
            }

            const float attackSec = adsrNormalizedToSeconds(inst.attack, 2.0f);
            const float decaySec = adsrNormalizedToSeconds(inst.decay, 2.0f);
            const float releaseSec = adsrNormalizedToSeconds(inst.release, 3.0f);
            const float sustainLevel = std::clamp(inst.sustain, 0.0f, 1.0f);

            float noteDurationSec = 3600.0f;
            if (voice.releasing && voice.releaseSample >= voice.startSample) {
                noteDurationSec = static_cast<float>(
                    static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate);
            }

            const float envGain = samplerAdsrGain(elapsedSec,
                                                  noteDurationSec,
                                                  attackSec,
                                                  decaySec,
                                                  sustainLevel,
                                                  releaseSec);
            if (envGain <= 0.0f) {
                if (voice.releasing) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            const float velGain = (voice.velocity / 100.0f) * inst.gain * kInstrumentOutputGain;

            if (inst.kind == LiveInstrumentKind::Oscillator) {
                const float hz = midiNoteToHz(voice.pitch);
                const float phaseInc = static_cast<float>(2.0 * 3.14159265358979323846 * hz / sampleRate);
                const float sample = std::sin(voice.oscillatorPhase) * envGain * velGain;
                voice.oscillatorPhase += phaseInc;
                if (voice.oscillatorPhase > 6.28318530718f) {
                    voice.oscillatorPhase -= 6.28318530718f;
                }
                mix += sample;
            } else if (inst.kind == LiveInstrumentKind::Sampler && inst.samplerPcm != nullptr &&
                       inst.samplerFrameCount > 1) {
                const int startFrame = inst.trimStartFrame;
                const int endFrame =
                    inst.trimEndFrame > startFrame ? inst.trimEndFrame : inst.samplerFrameCount;
                if (endFrame - startFrame <= 1) {
                    continue;
                }

                const double pitchRatio =
                    std::pow(2.0, static_cast<double>(voice.pitch - inst.rootPitch) / 12.0);
                const double readPos =
                    static_cast<double>(startFrame) + elapsedSec * inst.samplerPcmSampleRate * pitchRatio;
                if (readPos < static_cast<double>(startFrame) ||
                    readPos >= static_cast<double>(endFrame - 1)) {
                    if (voice.releasing && elapsedSec > noteDurationSec + releaseSec) {
                        voice.active.store(0, std::memory_order_release);
                    }
                    continue;
                }
                const int index = static_cast<int>(readPos);
                const float frac = static_cast<float>(readPos - static_cast<double>(index));
                const int next = std::min(index + 1, inst.samplerFrameCount - 1);
                float sample = inst.samplerPcm[index] * (1.0f - frac) + inst.samplerPcm[next] * frac;

                BiquadCoeffs coeffs{};
                cookSamplerBiquad(coeffs,
                                  inst.filterMode,
                                  static_cast<float>(sampleRate),
                                  normalizedCutoffToHz(inst.filterCutoff),
                                  normalizedQToValue(inst.filterQ));
                sample = processBiquadSample(sample, coeffs, voice.filterState);
                mix += sample * envGain * velGain;
            }
        }

        monoOut[frame] += mix;
    }
}

} // namespace audioapp
