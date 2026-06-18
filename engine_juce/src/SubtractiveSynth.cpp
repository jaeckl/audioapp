#include "audioapp/SubtractiveSynth.hpp"

#include "audioapp/DeviceChain.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplerFilter.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

constexpr float kSubtractivePi = 3.14159265358979323846f;
constexpr float kSubtractiveTwoPi = 6.28318530718f;

namespace {

constexpr float kPi = kSubtractivePi;
constexpr float kTwoPi = kSubtractiveTwoPi;

float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0;
}

float noiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

bool isSubtractiveNoteAudible(const SubtractiveMidiNoteRegion& note,
                              double beat,
                              int bpm,
                              float releaseSec,
                              double& elapsedSecondsOut,
                              double& noteDurationSecOut,
                              bool& inReleaseOut) noexcept {
    if (beat < note.clipStartBeat || beat >= note.clipStartBeat + note.clipLengthBeats || bpm <= 0) {
        return false;
    }

    const double posInClip = beat - note.clipStartBeat;
    const double loopedBeat = std::fmod(posInClip, note.clipLengthBeats);
    const double noteStart = note.noteStartBeat;
    const double noteEnd = note.noteStartBeat + note.noteDurationBeats;
    const double releaseBeats =
        static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;

    if (loopedBeat < noteStart) {
        return false;
    }

    const double elapsedBeats = loopedBeat - noteStart;
    elapsedSecondsOut = static_cast<float>(elapsedBeats * 60.0 / static_cast<double>(bpm));
    noteDurationSecOut = static_cast<float>(note.noteDurationBeats * 60.0 / static_cast<double>(bpm));
    inReleaseOut = loopedBeat >= noteEnd;

    if (loopedBeat < noteEnd) {
        return true;
    }
    return loopedBeat < noteEnd + releaseBeats;
}

} // namespace

float subtractiveNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

float renderOscBank(float shape,
                    float rootHz,
                    float detuneCents,
                    float level,
                    int unisonCount,
                    float unisonSpread,
                    float* phases,
                    double sampleRate,
                    bool* wrappedOut = nullptr,
                    const bool* masterWrapped = nullptr,
                    float* freePhases = nullptr,
                    float syncAmount = 0.0f) noexcept {
    if (level <= 0.0f || unisonCount <= 0) {
        return 0.0f;
    }

    const float sync = std::clamp(syncAmount, 0.0f, 1.0f);
    const bool hardSyncSlave = masterWrapped != nullptr && sync > 0.001f;
    float sum = 0.0f;
    for (int u = 0; u < unisonCount; ++u) {
        const float spread = unisonCount > 1
            ? (static_cast<float>(u) / static_cast<float>(unisonCount - 1) - 0.5f) * 2.0f
            : 0.0f;
        const float cents = detuneCents + spread * unisonSpread;
        const float hz = rootHz * std::pow(2.0f, cents / 1200.0f);
        const float phaseInc = kSubtractiveTwoPi * hz / static_cast<float>(sampleRate);

        if (!hardSyncSlave) {
            phases[u] += phaseInc;
            bool wrapped = false;
            if (phases[u] >= kSubtractiveTwoPi) {
                phases[u] -= kSubtractiveTwoPi;
                wrapped = true;
            }
            if (wrappedOut != nullptr) {
                wrappedOut[u] = wrapped;
            }
            sum += subtractiveMorphWaveSample(shape, phases[u]);
            continue;
        }

        float& freePhase = freePhases != nullptr ? freePhases[u] : phases[u];
        freePhase += phaseInc;
        if (freePhase >= kSubtractiveTwoPi) {
            freePhase -= kSubtractiveTwoPi;
        }

        if (masterWrapped[u]) {
            phases[u] = 0.0f;
        } else {
            phases[u] += phaseInc;
            if (phases[u] >= kSubtractiveTwoPi) {
                phases[u] -= kSubtractiveTwoPi;
            }
        }

        const float hardSample = subtractiveMorphWaveSample(shape, phases[u]);
        const float freeSample = subtractiveMorphWaveSample(shape, freePhase);
        sum += hardSample * sync + freeSample * (1.0f - sync);
    }
    return (sum / static_cast<float>(unisonCount)) * level;
}

float subtractiveVoiceSample(SubtractiveVoiceRuntime& voice,
                  const SubtractiveSynthParams& params,
                  float ampGain,
                  float filterGain,
                  double sampleRate,
                  float glideCoeff) noexcept {
    if (glideCoeff > 0.0f && glideCoeff < 1.0f) {
        voice.currentHz += (voice.targetHz - voice.currentHz) * glideCoeff;
    } else {
        voice.currentHz = voice.targetHz;
    }

    const int unisonCount = subtractiveUnisonCount(params.unisonVoices);
    const float spreadCents = params.unisonDetune * 50.0f;

    const float osc1Root =
        subtractiveOscPitchHz(voice.pitch, params.osc1Octave, params.osc1Semi, params.osc1Detune);
    const float osc2Root =
        subtractiveOscPitchHz(voice.pitch, params.osc2Octave, params.osc2Semi, params.osc2Detune);
    const float pitchRatio = voice.currentHz / subtractiveOscPitchHz(voice.pitch, 0.5f, 0.0f, 0.5f);

    const float mix = std::clamp(params.oscMix, 0.0f, 1.0f);
    const float peakLevel = 0.85f;
    const float osc1Level = std::sqrt(1.0f - mix) * peakLevel;
    const float osc2Level = std::sqrt(mix) * peakLevel;

    const float osc1Hz = osc1Root * pitchRatio;
    bool osc1Wrapped[kSubtractiveMaxUnison]{};
    const float osc1 = renderOscBank(params.osc1Shape,
                                     osc1Hz,
                                     0.0f,
                                     osc1Level,
                                     unisonCount,
                                     spreadCents,
                                     voice.osc1Phases,
                                     sampleRate,
                                     osc1Wrapped);
    const float syncAmount =
        std::clamp(params.osc1Sync, 0.0f, 1.0f) * std::clamp(params.osc2Sync, 0.0f, 1.0f);
    const float osc2 = renderOscBank(params.osc2Shape,
                                     osc2Root * pitchRatio,
                                     0.0f,
                                     osc2Level,
                                     unisonCount,
                                     spreadCents,
                                     voice.osc2Phases,
                                     sampleRate,
                                     nullptr,
                                     osc1Wrapped,
                                     voice.osc2FreePhases,
                                     syncAmount);

    float mixed = subtractiveMixOscPair(osc1, osc2, params.oscMixMode, 1.0f);
    if (params.noiseLevel > 0.0f) {
        mixed += subtractiveNoiseSample(voice.noiseSeed) * params.noiseLevel;
    }

    const float baseCutoff = normalizedCutoffToHz(params.filterCutoff);
    const float envCutoff = baseCutoff * (1.0f + filterGain * params.filterEnvAmount * 4.0f);
    const float cutoffHz = std::clamp(envCutoff, 20.0f, 20000.0f);
    const int filterMode = std::clamp(params.filterMode, 0, 4);
    if (filterMode == 4) {
        const int delaySamples = combDelaySamples(static_cast<float>(sampleRate), cutoffHz);
        const float feedback = 0.5f + normalizedQToValue(params.filterQ) * 0.06f;
        mixed = processCombSample(mixed, voice.combState, delaySamples, feedback);
    } else {
        BiquadCoeffs coeffs{};
        cookSamplerBiquad(coeffs,
                          filterMode,
                          static_cast<float>(sampleRate),
                          cutoffHz,
                          normalizedQToValue(params.filterQ));
        mixed = processBiquadSample(mixed, coeffs, voice.filterState);
    }
    return mixed * ampGain;
}

float subtractiveWaveSample(int wave, float phase) noexcept {
    const float wrapped = std::fmod(phase, kTwoPi);
    switch (wave) {
    case 0:
        return std::sin(wrapped);
    case 1: {
        const float t = wrapped / kPi;
        return t <= 1.0f ? (2.0f * t - 1.0f) : (3.0f - 2.0f * t);
    }
    case 2:
        return (2.0f / kPi) * (wrapped - kPi);
    case 3:
        return wrapped < kPi ? 1.0f : -1.0f;
    case 4:
    default:
        return wrapped < kPi ? 1.0f : -0.2f;
    }
}

float subtractiveMorphWaveSample(float shape, float phase) noexcept {
    const float scaled = std::clamp(shape, 0.0f, 1.0f) * 4.0f;
    const int i0 = std::min(4, static_cast<int>(scaled));
    const int i1 = std::min(4, i0 + 1);
    const float t = scaled - static_cast<float>(i0);
    const float a = subtractiveWaveSample(i0, phase);
    const float b = subtractiveWaveSample(i1, phase);
    return a * (1.0f - t) + b * t;
}

int subtractiveUnisonCount(float normalized) noexcept {
    const float clamped = std::clamp(normalized, 0.0f, 1.0f);
    return 1 + static_cast<int>(std::lround(clamped * static_cast<float>(kSubtractiveMaxUnison - 1)));
}

float subtractiveOscPitchHz(int rootPitch,
                            float octaveNorm,
                            float semiNorm,
                            float detuneNorm) noexcept {
    const int octaveOffset = static_cast<int>(std::lround((octaveNorm - 0.5f) * 4.0f));
    const int semiOffset = static_cast<int>(std::lround(semiNorm * 11.0f));
    const float cents = (detuneNorm - 0.5f) * 100.0f;
    const int pitch = rootPitch + octaveOffset * 12 + semiOffset;
    return midiNoteToHz(pitch) * std::pow(2.0f, cents / 1200.0f);
}

float subtractiveMixOscPair(float osc1, float osc2, int mixMode, float osc2Level) noexcept {
    switch (mixMode) {
    case 1:
        return osc1 - osc2 * osc2Level;
    case 2:
        return osc1 * osc2;
    case 3:
        return (osc1 >= 0.0f ? 1.0f : -1.0f) * osc2;
    case 4:
        return (std::abs(osc1) >= std::abs(osc2) ? osc1 : osc2);
    case 0:
    default:
        return osc1 * (1.0f - osc2Level) + osc2 * osc2Level;
    }
}

void renderSubtractiveLiveVoice(float& mix,
                                SubtractiveVoiceRuntime& voice,
                                const SubtractiveSynthParams& params,
                                double sampleRate,
                                uint64_t sampleIndex,
                                uint64_t blockStartSample) noexcept {
    if (voice.active == 0) {
        return;
    }

    const double elapsedSec =
        static_cast<double>(sampleIndex - blockStartSample) / sampleRate + voice.startBeat;
    (void)elapsedSec;

    const float ampAttackSec = adsrNormalizedToSeconds(params.ampAttack, 2.0f);
    const float ampDecaySec = adsrNormalizedToSeconds(params.ampDecay, 2.0f);
    const float ampReleaseSec = adsrNormalizedToSeconds(params.ampRelease, 3.0f);
    const float ampSustain = std::clamp(params.ampSustain, 0.0f, 1.0f);

    const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
    const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
    const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
    const float filterSustain = std::clamp(params.filterSustain, 0.0f, 1.0f);

    const double voiceElapsed =
        static_cast<double>(sampleIndex) / sampleRate - voice.startBeat;
    if (voiceElapsed < 0.0) {
        return;
    }

    float noteDurationSec = 3600.0f;
    if (voice.releaseBeat >= 0.0) {
        noteDurationSec = static_cast<float>(voice.releaseBeat - voice.startBeat);
        if (noteDurationSec < 0.0f) {
            noteDurationSec = 0.0f;
        }
    }

    const float ampGain = samplerAdsrGain(static_cast<float>(voiceElapsed),
                                          noteDurationSec,
                                          ampAttackSec,
                                          ampDecaySec,
                                          ampSustain,
                                          ampReleaseSec);
    if (ampGain <= 0.0f) {
        if (voice.releaseBeat >= 0.0) {
            voice.active = 0;
        }
        return;
    }

    const float filterGain = samplerAdsrGain(static_cast<float>(voiceElapsed),
                                             noteDurationSec,
                                             filterAttackSec,
                                             filterDecaySec,
                                             filterSustain,
                                             filterReleaseSec);

    const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
    const float velGain = 1.0f - params.velocitySensitivity * (1.0f - vel);

    const float glideMs = params.glideMs * 2000.0f;
    const float glideCoeff =
        glideMs > 0.0f ? 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * glideMs * 0.001f))
                       : 1.0f;

    mix += subtractiveVoiceSample(voice, params, ampGain * velGain, filterGain, sampleRate, glideCoeff) *
           params.gain * kInstrumentOutputGain;
}

void mixSubtractiveMidiNotesBlock(float* monoOut,
                                  int numFrames,
                                  double sampleRate,
                                  int bpm,
                                  double playheadStartBeat,
                                  const SubtractiveMidiNoteRegion* notes,
                                  int noteCount,
                                  const SubtractiveSynthParams& params,
                                  SubtractiveSynthRuntime& runtime) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const float ampReleaseSec = adsrNormalizedToSeconds(params.ampRelease, 3.0f);
    const float ampAttackSec = adsrNormalizedToSeconds(params.ampAttack, 2.0f);
    const float ampDecaySec = adsrNormalizedToSeconds(params.ampDecay, 2.0f);
    const float ampSustain = std::clamp(params.ampSustain, 0.0f, 1.0f);
    const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
    const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
    const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
    const float filterSustain = std::clamp(params.filterSustain, 0.0f, 1.0f);
    const float glideMs = params.glideMs * 2000.0f;
    const float glideCoeff =
        glideMs > 0.0f ? 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * glideMs * 0.001f))
                       : 1.0f;

    const double blockStartBeat = playheadStartBeat;

    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(blockStartBeat, frame, sampleRate, bpm);
        float mix = 0.0f;

        struct ActiveNote {
            int noteKey;
            int pitch;
            float velocity;
            float elapsedSec;
            float noteDurationSec;
        };
        ActiveNote active[kSubtractiveMaxVoices];
        int activeCount = 0;

        for (int noteIndex = 0; noteIndex < noteCount && activeCount < kSubtractiveMaxVoices; ++noteIndex) {
            const auto& note = notes[noteIndex];
            double elapsedSeconds = 0.0;
            double noteDurationSec = 0.0;
            bool inRelease = false;
            if (!isSubtractiveNoteAudible(
                    note, beat, bpm, ampReleaseSec, elapsedSeconds, noteDurationSec, inRelease)) {
                continue;
            }
            active[activeCount++] = ActiveNote{
                note.noteKey,
                note.pitch,
                note.velocity,
                static_cast<float>(elapsedSeconds),
                static_cast<float>(noteDurationSec),
            };
        }

        bool slotUsed[kSubtractiveMaxVoices]{};
        for (int i = 0; i < activeCount; ++i) {
            const ActiveNote& note = active[i];
            int voiceIndex = -1;
            for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
                auto& voice = runtime.voices[v];
                if (voice.active != 0 && voice.noteKey == note.noteKey && voice.pitch == note.pitch) {
                    voiceIndex = v;
                    break;
                }
            }
            if (voiceIndex < 0) {
                for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
                    if (runtime.voices[v].active == 0) {
                        voiceIndex = v;
                        break;
                    }
                }
            }
            if (voiceIndex < 0) {
                voiceIndex = runtime.stealIndex;
                runtime.stealIndex = (runtime.stealIndex + 1) % kSubtractiveMaxVoices;
            }

            auto& voice = runtime.voices[voiceIndex];
            if (!slotUsed[voiceIndex]) {
                if (voice.active == 0 || voice.noteKey != note.noteKey || voice.pitch != note.pitch) {
                    std::memset(&voice, 0, sizeof(voice));
                    voice.active = 1;
                    voice.pitch = note.pitch;
                    voice.noteKey = note.noteKey;
                    voice.velocity = note.velocity;
                    voice.targetHz = subtractiveOscPitchHz(note.pitch, 0.5f, 0.0f, 0.5f);
                    voice.currentHz = voice.targetHz;
                    voice.noiseSeed = 0.1f + static_cast<float>(note.noteKey) * 0.013f;
                }
                slotUsed[voiceIndex] = true;
            }

            voice.targetHz = subtractiveOscPitchHz(note.pitch, 0.5f, 0.0f, 0.5f);
            const float ampGain = samplerAdsrGain(note.elapsedSec,
                                                  note.noteDurationSec,
                                                  ampAttackSec,
                                                  ampDecaySec,
                                                  ampSustain,
                                                  ampReleaseSec);
            const float filterGain = samplerAdsrGain(note.elapsedSec,
                                                     note.noteDurationSec,
                                                     filterAttackSec,
                                                     filterDecaySec,
                                                     filterSustain,
                                                     filterReleaseSec);
            const float vel = std::clamp(note.velocity / 127.0f, 0.0f, 1.0f);
            const float velGain = 1.0f - params.velocitySensitivity * (1.0f - vel);

            mix += subtractiveVoiceSample(voice, params, ampGain * velGain, filterGain, sampleRate, glideCoeff) *
                   params.gain * kInstrumentOutputGain;
        }

        for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
            if (!slotUsed[v]) {
                runtime.voices[v].active = 0;
            }
        }

        monoOut[frame] += mix;
    }
}

} // namespace audioapp
