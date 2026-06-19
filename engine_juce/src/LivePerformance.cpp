#include "audioapp/LivePerformance.hpp"

#include "audioapp/MasterMix.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/KickGenerator.hpp"
#include "audioapp/SnareGenerator.hpp"
#include "audioapp/ClapGenerator.hpp"
#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/CrashGenerator.hpp"
#include "audioapp/SubtractiveSynth.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

namespace {

void initSubtractiveVoice(SubtractiveVoiceRuntime& voice, int pitch, float velocity) noexcept {
    voice.active = 1;
    voice.pitch = pitch;
    voice.velocity = velocity;
    voice.targetHz = subtractiveOscPitchHz(pitch, 0.5f, 0.0f, 0.5f);
    voice.currentHz = voice.targetHz;
    voice.noiseSeed = 0.2f + static_cast<float>(pitch) * 0.003f;
}

} // namespace

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
        if (voice.instrument.kind == LiveInstrumentKind::SubtractiveSynth) {
            voice.subtractiveReleaseSec = static_cast<double>(now) / 48000.0;
        }
    }
}

int LivePerformanceMixer::noteOn(const LiveInstrumentSnapshot& instrument, int pitch, float velocity) noexcept {
    if (instrument.kind == LiveInstrumentKind::None) {
        return -1;
    }
    const uint64_t now = sampleClock();
    const bool subtractive = instrument.kind == LiveInstrumentKind::SubtractiveSynth;
    const bool mono = subtractive && instrument.subtractive.synthMono >= 0.5f;
    const bool legato = subtractive && instrument.subtractive.synthLegato >= 0.5f;

    if (subtractive && mono) {
        LiveVoiceSlot* reuse = nullptr;
        for (auto& voice : voices_) {
            if (voice.active.load(std::memory_order_acquire) == 0 ||
                voice.instrument.kind != LiveInstrumentKind::SubtractiveSynth ||
                voice.releasing) {
                continue;
            }
            reuse = &voice;
            break;
        }

        for (auto& voice : voices_) {
            if (voice.active.load(std::memory_order_acquire) == 0 ||
                voice.instrument.kind != LiveInstrumentKind::SubtractiveSynth) {
                continue;
            }
            if (&voice != reuse) {
                releaseVoice(voice, now);
            }
        }

        if (reuse != nullptr) {
            if (legato) {
                reuse->instrument = instrument;
                reuse->pitch = pitch;
                reuse->velocity = std::clamp(velocity, 1.0f, 127.0f);
                reuse->subtractive.pitch = pitch;
                reuse->subtractive.velocity = reuse->velocity;
                return static_cast<int>(reuse - voices_);
            }

            reuse->instrument = instrument;
            reuse->pitch = pitch;
            reuse->velocity = std::clamp(velocity, 1.0f, 127.0f);
            reuse->startSample = now;
            reuse->releaseSample = 0;
            reuse->releasing = false;
            reuse->subtractiveStartSec = static_cast<double>(now) / 48000.0;
            reuse->subtractiveReleaseSec = -1.0;
            std::memset(&reuse->subtractive, 0, sizeof(reuse->subtractive));
            initSubtractiveVoice(reuse->subtractive, pitch, reuse->velocity);
            return static_cast<int>(reuse - voices_);
        }
    } else {
        for (auto& voice : voices_) {
            if (voice.active.load(std::memory_order_acquire) != 0 && voice.pitch == pitch && !voice.releasing) {
                releaseVoice(voice, now);
            }
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
        voice.subtractive = SubtractiveVoiceRuntime{};
        voice.kick = KickVoiceRuntime{};
        voice.snare = SnareVoiceRuntime{};
        voice.clap = ClapVoiceRuntime{};
        voice.cymbal = CymbalVoiceRuntime{};
        voice.crash = CrashVoiceRuntime{};
        voice.subtractiveStartSec = static_cast<double>(now) / 48000.0;
        voice.subtractiveReleaseSec = -1.0;
        if (instrument.kind == LiveInstrumentKind::SubtractiveSynth) {
            initSubtractiveVoice(voice.subtractive, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::KickGenerator) {
            triggerKickVoice(voice.kick, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::SnareGenerator) {
            triggerSnareVoice(voice.snare, pitch, voice.velocity);
            configureSnareVoice(voice.snare, instrument.snare, 48000.0f);
        } else if (instrument.kind == LiveInstrumentKind::ClapGenerator) {
            triggerClapVoice(voice.clap, voice.velocity, instrument.clap);
        } else if (instrument.kind == LiveInstrumentKind::CymbalGenerator) {
            triggerCymbalVoice(voice.cymbal, pitch, voice.velocity);
        } else if (instrument.kind == LiveInstrumentKind::CrashGenerator) {
            triggerCrashVoice(voice.crash, pitch, voice.velocity);
        }
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
    steal.subtractive = SubtractiveVoiceRuntime{};
    steal.kick = KickVoiceRuntime{};
    steal.snare = SnareVoiceRuntime{};
    steal.clap = ClapVoiceRuntime{};
    steal.cymbal = CymbalVoiceRuntime{};
    steal.crash = CrashVoiceRuntime{};
    steal.subtractiveStartSec = static_cast<double>(now) / 48000.0;
    steal.subtractiveReleaseSec = -1.0;
    if (instrument.kind == LiveInstrumentKind::SubtractiveSynth) {
        initSubtractiveVoice(steal.subtractive, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::KickGenerator) {
        triggerKickVoice(steal.kick, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::SnareGenerator) {
        triggerSnareVoice(steal.snare, pitch, steal.velocity);
        configureSnareVoice(steal.snare, instrument.snare, 48000.0f);
    } else if (instrument.kind == LiveInstrumentKind::ClapGenerator) {
        triggerClapVoice(steal.clap, steal.velocity, instrument.clap);
    } else if (instrument.kind == LiveInstrumentKind::CymbalGenerator) {
        triggerCymbalVoice(steal.cymbal, pitch, steal.velocity);
    } else if (instrument.kind == LiveInstrumentKind::CrashGenerator) {
        triggerCrashVoice(steal.crash, pitch, steal.velocity);
    }
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

            if (inst.kind == LiveInstrumentKind::KickGenerator) {
                auto& kv = voice.kick;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (kv.active == 0) {
                    triggerKickVoice(kv, voice.pitch, voice.velocity);
                }
                kv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.kick.kickVelocity * (1.0f - vel);
                mix += kickGeneratorSample(kv, inst.kick, sampleRate, velGain);
                if (kv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::SnareGenerator) {
                auto& sv = voice.snare;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (sv.active == 0) {
                    triggerSnareVoice(sv, voice.pitch, voice.velocity);
                    configureSnareVoice(sv, inst.snare, static_cast<float>(sampleRate));
                }
                sv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.snare.snareVelocity * (1.0f - vel);
                mix += snareGeneratorSample(sv, inst.snare, sampleRate, velGain);
                if (sv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::ClapGenerator) {
                auto& cv = voice.clap;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (cv.active == 0) {
                    triggerClapVoice(cv, voice.velocity, inst.clap);
                }
                cv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 0.5f + vel * 0.5f;
                mix += clapGeneratorSample(cv, inst.clap, sampleRate, velGain);
                if (cv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::CymbalGenerator) {
                auto& cyv = voice.cymbal;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (cyv.active == 0) {
                    triggerCymbalVoice(cyv, voice.pitch, voice.velocity);
                }
                cyv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.cymbal.cymbalVelocity * (1.0f - vel);
                mix += (cymbalGeneratorSampleL(cyv, inst.cymbal, sampleRate, velGain) +
                        cymbalGeneratorSampleR(cyv, inst.cymbal, sampleRate, velGain)) * 0.5f;
                if (cyv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

            if (inst.kind == LiveInstrumentKind::CrashGenerator) {
                auto& crv = voice.crash;
                const double elapsedSec =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                if (elapsedSec < 0.0) {
                    continue;
                }
                if (crv.active == 0) {
                    triggerCrashVoice(crv, voice.pitch, voice.velocity);
                }
                crv.elapsedSec = elapsedSec;
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velGain = 1.0f - inst.crash.crashVelocity * (1.0f - vel);
                mix += (crashGeneratorSampleL(crv, inst.crash, sampleRate, velGain) +
                        crashGeneratorSampleR(crv, inst.crash, sampleRate, velGain)) * 0.5f;
                if (crv.active == 0) {
                    voice.active.store(0, std::memory_order_release);
                }
                continue;
            }

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

            if (inst.kind == LiveInstrumentKind::SubtractiveSynth) {
                const auto& params = inst.subtractive;
                const float ampAttackSec = adsrNormalizedToSeconds(params.ampAttack, 2.0f);
                const float ampDecaySec = adsrNormalizedToSeconds(params.ampDecay, 2.0f);
                const float ampReleaseSec = adsrNormalizedToSeconds(params.ampRelease, 3.0f);
                const float ampSustain = std::clamp(params.ampSustain, 0.0f, 1.0f);
                const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
                const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
                const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
                const float filterSustain = std::clamp(params.filterSustain, 0.0f, 1.0f);

                const double voiceElapsed =
                    static_cast<double>(sampleIndex - voice.startSample) / sampleRate;
                float noteDurationSec = 3600.0f;
                if (voice.releasing && voice.releaseSample >= voice.startSample) {
                    noteDurationSec = static_cast<float>(
                        static_cast<double>(voice.releaseSample - voice.startSample) / sampleRate);
                }

                const float ampGain = samplerAdsrGain(static_cast<float>(voiceElapsed),
                                                      noteDurationSec,
                                                      ampAttackSec,
                                                      ampDecaySec,
                                                      ampSustain,
                                                      ampReleaseSec);
                if (ampGain <= 0.0f) {
                    if (voice.releasing) {
                        voice.active.store(0, std::memory_order_release);
                    }
                    continue;
                }

                const float filterGain = samplerAdsrGain(static_cast<float>(voiceElapsed),
                                                         noteDurationSec,
                                                         filterAttackSec,
                                                         filterDecaySec,
                                                         filterSustain,
                                                         filterReleaseSec);
                const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
                const float velAmount =
                    1.0f - params.velocitySensitivity * (1.0f - vel);
                const float glideMs = params.glideMs * 2000.0f;
                const float glideCoeff =
                    glideMs > 0.0f
                        ? 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * glideMs * 0.001f))
                        : 1.0f;

                auto& sv = voice.subtractive;
                sv.targetHz =
                    subtractiveOscPitchHz(voice.pitch, 0.5f, 0.0f, 0.5f);
                sv.pitch = voice.pitch;
                sv.velocity = voice.velocity;
                mix += subtractiveVoiceSample(sv,
                                                params,
                                                ampGain * velAmount,
                                                filterGain,
                                                sampleRate,
                                                glideCoeff) *
                        params.gain * kInstrumentOutputGain;
            } else if (inst.kind == LiveInstrumentKind::Oscillator) {
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
                const double readPosRaw =
                    static_cast<double>(startFrame) + elapsedSec * inst.samplerPcmSampleRate * pitchRatio;

                // Check if a region is set for looping
                const bool hasRegion = inst.regionEndFrame > 0 && inst.regionEndFrame > inst.regionStartFrame;
                double readPos;
                if (hasRegion) {
                    const int loopLen = inst.regionEndFrame - inst.regionStartFrame;
                    const double regionProgress = elapsedSec * inst.samplerPcmSampleRate * pitchRatio;
                    readPos = static_cast<double>(inst.regionStartFrame) +
                        std::fmod(regionProgress, static_cast<double>(loopLen));
                } else {
                    if (readPosRaw < static_cast<double>(startFrame) ||
                        readPosRaw >= static_cast<double>(endFrame - 1)) {
                        if (voice.releasing && elapsedSec > noteDurationSec + releaseSec) {
                            voice.active.store(0, std::memory_order_release);
                        }
                        continue;
                    }
                    readPos = readPosRaw;
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
