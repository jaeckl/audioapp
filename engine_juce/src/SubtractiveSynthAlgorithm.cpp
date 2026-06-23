#include "audioapp/SubtractiveSynthAlgorithm.hpp"

#include "audioapp/AutomationPlayback.hpp"
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

static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

constexpr float kPi = kSubtractivePi;
constexpr float kTwoPi = kSubtractiveTwoPi;

float noiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

float applyFilterShaper(float sample, int mode, float amount) noexcept {
    const float amt = safe_clamp(amount, 0.0f, 1.0f);
    const int shaperMode = safe_clamp(mode, 0, 3);
    if (amt <= 0.0f || shaperMode == 0) {
        return sample;
    }

    float shaped = sample;
    switch (shaperMode) {
    case 1:
        shaped = std::tanh(sample * 2.5f);
        break;
    case 2:
        shaped = safe_clamp(sample * 3.0f, -1.0f, 1.0f);
        break;
    case 3:
        shaped = std::sin(sample * kPi * 1.5f);
        break;
    default:
        break;
    }
    return sample * (1.0f - amt) + shaped * amt;
}

} // namespace

float subtractiveNoiseSample(float& seed) noexcept {
    seed = std::fmod(seed * 16807.0f, 2147483647.0f);
    return (seed / 1073741823.5f) - 1.0f;
}

/// Precompute per-unison phase increment per unit root Hz.
/// phaseIncPerUnit[u] = 2pi * 2^(cents/1200) / sampleRate
/// Per-sample phase increment: rootHz * phaseIncPerUnit[u]
static void precomputeBankIncrements(float* phaseIncPerUnit,
                                      int unisonCount,
                                      float detuneCents,
                                      float unisonSpread,
                                      double sampleRate) noexcept {
    if (phaseIncPerUnit == nullptr || unisonCount <= 0) return;
    const float invSampleRate = 1.0f / static_cast<float>(sampleRate);
    for (int u = 0; u < unisonCount; ++u) {
        const float spread = unisonCount > 1
            ? (static_cast<float>(u) / static_cast<float>(unisonCount - 1) - 0.5f) * 2.0f
            : 0.0f;
        const float cents = detuneCents + spread * unisonSpread;
        phaseIncPerUnit[u] = kSubtractiveTwoPi * std::pow(2.0f, cents / 1200.0f) * invSampleRate;
    }
}

float renderOscBank(float shape,
                    float rootHz,
                    const float* phaseIncPerUnit,
                    int unisonCount,
                    float level,
                    float* phases,
                    bool* wrappedOut = nullptr,
                    const bool* masterWrapped = nullptr,
                    float* freePhases = nullptr,
                    float syncAmount = 0.0f) noexcept {
    if (level <= 0.0f || unisonCount <= 0 || phaseIncPerUnit == nullptr) {
        return 0.0f;
    }

    const float sync = safe_clamp(syncAmount, 0.0f, 1.0f);
    const bool hardSyncSlave = masterWrapped != nullptr && sync > 0.001f;
    float sum = 0.0f;
    for (int u = 0; u < unisonCount; ++u) {
        const float phaseInc = rootHz * phaseIncPerUnit[u];

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
    const int globalSemi =
        static_cast<int>(std::lround((params.globalPitch - 0.5f) * 24.0f));
    const int effectivePitch = voice.pitch + globalSemi;
    const float glideTargetHz =
        subtractiveOscPitchHz(effectivePitch, 0.5f, 0.0f, 0.5f);
    if (glideCoeff > 0.0f && glideCoeff < 1.0f) {
        voice.currentHz += (glideTargetHz - voice.currentHz) * glideCoeff;
    } else {
        voice.currentHz = glideTargetHz;
    }
    voice.targetHz = glideTargetHz;

    const int unisonCount = subtractiveUnisonCount(params.unisonVoices);
    const float spreadCents = params.unisonDetune * 50.0f;

    // Refresh precomputed per-unison increments when unison count or detune changes
    if (unisonCount != voice.cachedUnisonCount) {
        precomputeBankIncrements(voice.osc1PhaseIncPerUnit, unisonCount, 0.0f, spreadCents, sampleRate);
        precomputeBankIncrements(voice.osc2PhaseIncPerUnit, unisonCount, 0.0f, spreadCents, sampleRate);
        voice.cachedUnisonCount = unisonCount;
    }

    const float osc1Root =
        subtractiveOscPitchHz(effectivePitch, params.osc1Octave, params.osc1Semi, params.osc1Detune);
    const float osc2Root =
        subtractiveOscPitchHz(effectivePitch, params.osc2Octave, params.osc2Semi, params.osc2Detune);
    const float pitchRatio =
        voice.currentHz / subtractiveOscPitchHz(effectivePitch, 0.5f, 0.0f, 0.5f);

    const float mix = safe_clamp(params.oscMix, 0.0f, 1.0f);

    const float osc1Hz = osc1Root * pitchRatio;
    bool osc1Wrapped[kSubtractiveMaxUnison]{};
    const float osc1 = renderOscBank(params.osc1Shape,
                                     osc1Hz,
                                     voice.osc1PhaseIncPerUnit,
                                     unisonCount,
                                     1.0f,
                                     voice.osc1Phases,
                                     osc1Wrapped);
    const float syncAmount =
        safe_clamp(params.osc1Sync, 0.0f, 1.0f) * safe_clamp(params.osc2Sync, 0.0f, 1.0f);
    const float osc2 = renderOscBank(params.osc2Shape,
                                     osc2Root * pitchRatio,
                                     voice.osc2PhaseIncPerUnit,
                                     unisonCount,
                                     1.0f,
                                     voice.osc2Phases,
                                     nullptr,
                                     osc1Wrapped,
                                     voice.osc2FreePhases,
                                     syncAmount);

    float mixed = 0.0f;
    if (params.oscMixMode == 0) {
        mixed = ((1.0f - mix) * osc1 + mix * osc2) * 0.7f;
    } else {
        mixed = subtractiveMixOscPair(osc1, osc2, params.oscMixMode, mix) * 0.7f;
    }
    if (params.noiseLevel > 0.0f) {
        mixed += subtractiveNoiseSample(voice.noiseSeed) * params.noiseLevel * 0.25f;
    }

    const float fbAmt = safe_clamp(params.mixFeedback, 0.0f, 1.0f) * 0.35f;
    if (fbAmt > 0.0f) {
        mixed += std::tanh(voice.mixFeedbackSample) * fbAmt;
    }

    const float preDrive = safe_clamp(params.preDrive, 0.0f, 1.0f);
    if (preDrive > 0.0f) {
        mixed *= 1.0f + preDrive * 5.0f;
        mixed = std::tanh(mixed);
    }

    const float preHpCut = safe_clamp(params.preHpCutoff, 0.0f, 1.0f);
    if (preHpCut > 0.02f) {
        const float q = normalizedQToValue(safe_clamp(params.preHpRes, 0.0f, 1.0f));
        const float hpCutoffHz = safe_clamp(normalizedCutoffToHz(preHpCut), 20.0f, 20000.0f);
        // Cache preHP coefficients (rarely change per-block)
        if (std::abs(hpCutoffHz - voice.cachedPreHpCutoffHz) > 0.5f ||
            std::abs(q - voice.cachedPreHpQ) > 0.001f) {
            cookSamplerBiquad(voice.cachedPreHpCoeffs, 1,
                              static_cast<float>(sampleRate),
                              hpCutoffHz, q);
            voice.cachedPreHpCutoffHz = hpCutoffHz;
            voice.cachedPreHpQ = q;
        }
        mixed = processBiquadSample(mixed, voice.cachedPreHpCoeffs, voice.preHpState);
    }

    const float baseCutoff = normalizedCutoffToHz(params.filterCutoff);
    float envCutoff = baseCutoff * (1.0f + filterGain * params.filterEnvAmount * 4.0f);
    const float filterFm = safe_clamp(params.filterFm, 0.0f, 1.0f);
    if (filterFm > 0.0f) {
        const float fmMod = 1.0f + filterFm * osc2 * 3.0f;
        envCutoff *= safe_clamp(fmMod, 0.2f, 4.0f);
    }
    const float keyTrack = safe_clamp(params.filterKeyTrack, 0.0f, 1.0f);
    const float semitonesFromRef = static_cast<float>(effectivePitch - 60);
    const float keyTrackRatio = std::pow(2.0f, semitonesFromRef * keyTrack / 12.0f);
    const float rawCutoffHz =
        safe_clamp(envCutoff * keyTrackRatio, 20.0f, 20000.0f);

    if (voice.smoothCutoffHz <= 0.0f) {
        voice.smoothCutoffHz = rawCutoffHz;
    } else {
        voice.smoothCutoffHz += (rawCutoffHz - voice.smoothCutoffHz) * 0.05f;
    }
    const float cutoffHz = safe_clamp(voice.smoothCutoffHz, 20.0f, 20000.0f);
    const int filterMode = safe_clamp(params.filterMode, 0, 5);
    const float rawQ = normalizedQToValue(params.filterQ);
    const float q = filterMode == 4 ? std::min(rawQ, 4.0f) : rawQ;
    // Cache filter coefficients when params haven't changed meaningfully
    // cutoffHz changes per-sample from envelope/FM, so we cook every time
    if (filterMode == 4) {
        const int delaySamples = combDelaySamples(static_cast<float>(sampleRate), cutoffHz);
        const float feedback = std::min(0.88f, 0.45f + q * 0.08f);
        mixed = processCombSample(mixed, voice.combState, delaySamples, feedback);
    } else if (filterMode == 5) {
        if (filterMode != voice.cachedFilterMode ||
            std::abs(cutoffHz - voice.cachedFilterCutoffHz) > 0.5f ||
            std::abs(q - voice.cachedFilterQ) > 0.001f) {
            cookSamplerBiquad(voice.cachedFilterCoeffs, 0,
                              static_cast<float>(sampleRate), cutoffHz, q);
            voice.cachedFilterCutoffHz = cutoffHz;
            voice.cachedFilterQ = q;
            voice.cachedFilterMode = filterMode;
        }
        mixed = processBiquadSample(mixed, voice.cachedFilterCoeffs, voice.filterState);
        mixed = processBiquadSample(mixed, voice.cachedFilterCoeffs, voice.filterState2);
    } else {
        if (filterMode != voice.cachedFilterMode ||
            std::abs(cutoffHz - voice.cachedFilterCutoffHz) > 0.5f ||
            std::abs(q - voice.cachedFilterQ) > 0.001f) {
            cookSamplerBiquad(voice.cachedFilterCoeffs, filterMode,
                              static_cast<float>(sampleRate), cutoffHz, q);
            voice.cachedFilterCutoffHz = cutoffHz;
            voice.cachedFilterQ = q;
            voice.cachedFilterMode = filterMode;
        }
        mixed = processBiquadSample(mixed, voice.cachedFilterCoeffs, voice.filterState);
    }

    mixed = std::tanh(mixed * 0.75f) / 0.75f;

    const float filterDrive = safe_clamp(params.filterDrive, 0.0f, 1.0f);
    if (filterDrive > 0.0f) {
        mixed = std::tanh(mixed * (1.0f + filterDrive * 3.0f));
    }

    mixed = applyFilterShaper(mixed, params.filterShaperMode, params.filterShaper);

    voice.mixFeedbackSample = std::tanh(mixed);
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
        return (1.0f / kPi) * (wrapped - kPi);
    case 3:
        return wrapped < kPi ? 1.0f : -1.0f;
    case 4:
    default:
        return wrapped < kPi ? 1.0f : -0.2f;
    }
}

float subtractiveMorphWaveSample(float shape, float phase) noexcept {
    const float scaled = safe_clamp(shape, 0.0f, 1.0f) * 4.0f;
    const int i0 = std::min(4, static_cast<int>(scaled));
    const int i1 = std::min(4, i0 + 1);
    const float t = scaled - static_cast<float>(i0);
    const float a = subtractiveWaveSample(i0, phase);
    const float b = subtractiveWaveSample(i1, phase);
    return a * (1.0f - t) + b * t;
}

int subtractiveUnisonCount(float normalized) noexcept {
    const float clamped = safe_clamp(normalized, 0.0f, 1.0f);
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
        return osc1 + osc2;
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
    const float ampSustain = safe_clamp(params.ampSustain, 0.0f, 1.0f);

    const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
    const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
    const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
    const float filterSustain = safe_clamp(params.filterSustain, 0.0f, 1.0f);

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

    const float vel = safe_clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
    const float velGain = 1.0f - params.velocitySensitivity * (1.0f - vel);

    const float glideMs = params.glideMs * 2000.0f;
    const float glideCoeff =
        glideMs > 0.0f ? 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * glideMs * 0.001f))
                       : 1.0f;

    mix += subtractiveVoiceSample(voice, params, ampGain * velGain, filterGain, sampleRate, glideCoeff) *
           params.gain * kInstrumentOutputGain;
}

} // namespace audioapp