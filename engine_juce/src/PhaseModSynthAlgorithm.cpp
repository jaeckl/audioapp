#include "audioapp/PhaseModSynthAlgorithm.hpp"
#include "audioapp/PhaseModOscSimd.hpp"

#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplerFilter.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace audioapp {

// -----------------------------------------------------------------------
// Internal helpers
// -----------------------------------------------------------------------

namespace {

constexpr float kPM_Pi = 3.14159265358979323846f;
constexpr float kPM_TwoPi = 6.28318530718f;
static inline float safe_clamp(float v, float lo, float hi) noexcept {
    if (!std::isfinite(v)) return lo;
    return std::clamp(v, lo, hi);
}

/// Wave sample for a given wave type (same as subtractiveWaveSample).
static float pmWaveSample(int wave, float phase) noexcept {
    const float wrapped = std::fmod(phase, kPM_TwoPi);
    switch (wave) {
    case 0: // sine
        return std::sin(wrapped);
    case 1: { // triangle
        const float t = wrapped / kPM_Pi;
        return t <= 1.0f ? (2.0f * t - 1.0f) : (3.0f - 2.0f * t);
    }
    case 2: // saw
        return (1.0f / kPM_Pi) * (wrapped - kPM_Pi);
    case 3: // square
        return wrapped < kPM_Pi ? 1.0f : -1.0f;
    case 4: // pulse
    default:
        return wrapped < kPM_Pi ? 1.0f : -0.2f;
    }
}

/// Morph between sine/tri/saw/square/noise using a continuous shape [0,1].
static float pmMorphWaveSample(float shape, float phase) noexcept {
    const float scaled = safe_clamp(shape, 0.0f, 1.0f) * 4.0f;
    const int i0 = std::min(4, static_cast<int>(scaled));
    const int i1 = std::min(4, i0 + 1);
    const float t = scaled - static_cast<float>(i0);
    const float a = pmWaveSample(i0, phase);
    const float b = pmWaveSample(i1, phase);
    return a * (1.0f - t) + b * t;
}

/// Precompute per-unison phase increments.
/// Each unison voice gets a detune offset, then we compute
/// phaseInc = kPM_TwoPi * 2^(cents/1200) / sampleRate.
/// The caller multiplies by operator Hz each frame.
static void precomputePhaseIncs(float* opPhaseIncs,
                                int unisonCount,
                                float detuneCents,
                                double sampleRate) noexcept {
    if (opPhaseIncs == nullptr || unisonCount <= 0) return;
    const float invSr = 1.0f / static_cast<float>(sampleRate);
    // For each unison voice, the same detune applies across all 4 ops.
    // We store phaseInc per (unison, op) but detune is per-unison only.
    for (int u = 0; u < unisonCount; ++u) {
        const float spread = unisonCount > 1
            ? (static_cast<float>(u) / static_cast<float>(unisonCount - 1) - 0.5f) * 2.0f
            : 0.0f;
        const float cents = spread * detuneCents;
        const float scale = kPM_TwoPi * std::pow(2.0f, cents / 1200.0f) * invSr;
        for (int op = 0; op < kPhaseModOpsPerVoice; ++op) {
            const int idx = u * kPhaseModOpsPerVoice + op;
            opPhaseIncs[idx] = scale;
        }
    }
}

/// Per-operator ADSR envelope: advance envelope state for one sample.
/// Returns the current envelope level [0,1].
/// Envelope is retriggered externally by resetting envelopePhase[] to 0
/// and envelopeValue[] to 0.
static float pmAdvanceEnvelope(float& envValue,
                               int& envPhase,
                               float attackSec,
                               float decaySec,
                               float sustainLevel,
                               float releaseSec,
                               float sampleRate,
                               bool noteActive) noexcept {
    const float dt = 1.0f / static_cast<float>(sampleRate);

    switch (envPhase) {
    case 0: // Attack
        if (attackSec <= 0.0f) {
            envValue = 1.0f;
            envPhase = 1;
        } else {
            envValue += dt / attackSec;
            if (envValue >= 1.0f) {
                envValue = 1.0f;
                envPhase = 1;
            }
        }
        break;

    case 1: // Decay
        if (decaySec <= 0.0f) {
            envValue = sustainLevel;
            envPhase = 2;
        } else {
            envValue -= dt / decaySec * (1.0f - sustainLevel);
            if (envValue <= sustainLevel) {
                envValue = sustainLevel;
                envPhase = 2;
            }
        }
        break;

    case 2: // Sustain
        envValue = sustainLevel;
        if (!noteActive) {
            envPhase = 3;
        }
        break;

    case 3: // Release
        if (releaseSec <= 0.0f) {
            envValue = 0.0f;
            envPhase = 4;
        } else {
            envValue -= dt / releaseSec * sustainLevel;
            if (envValue <= 0.0f) {
                envValue = 0.0f;
                envPhase = 4;
            }
        }
        break;

    case 4: // Done
    default:
        envValue = 0.0f;
        break;
    }

    return safe_clamp(envValue, 0.0f, 1.0f);
}

/// Process a filter biquad per-voice, caching coefficients.
static float pmProcessFilter(float sample,
                             PhaseModSynthVoiceRuntime& voice,
                             const PhaseModSynthParams& params,
                             float filterEnvGain,
                             float sampleRate) noexcept {
    const float baseCutoff = normalizedCutoffToHz(params.filterCutoff);
    float envCutoff = baseCutoff * (1.0f + filterEnvGain * params.filterEnvAmount * 4.0f);

    // Key track
    const float kt = safe_clamp(params.filterKeyTrack, 0.0f, 1.0f);
    const float semitonesFromRef = static_cast<float>(voice.pitch - 60);
    const float ktRatio = std::pow(2.0f, semitonesFromRef * kt / 12.0f);
    float rawCutoffHz = safe_clamp(envCutoff * ktRatio, 20.0f, 20000.0f);

    // Smooth cutoff to avoid zipper noise
    if (voice.smoothCutoffHz <= 0.0f) {
        voice.smoothCutoffHz = rawCutoffHz;
    } else {
        voice.smoothCutoffHz += (rawCutoffHz - voice.smoothCutoffHz) * 0.05f;
    }
    const float cutoffHz = safe_clamp(voice.smoothCutoffHz, 20.0f, 20000.0f);
    const int filterMode = safe_clamp(params.filterMode, 0, 5);
    const float rawQ = normalizedQToValue(params.filterQ);
    const float q = filterMode == 4 ? std::min(rawQ, 4.0f) : rawQ;

    if (filterMode == 4) {
        // Comb filter mode
        const int delaySamples = combDelaySamples(static_cast<float>(sampleRate), cutoffHz);
        const float feedback = std::min(0.88f, 0.45f + q * 0.08f);
        return processCombSample(sample, voice.combFilterState, delaySamples, feedback);
    }

    if (filterMode == 5) {
        // 2-pole filter (cascaded)
        if (filterMode != voice.cachedFilterMode ||
            std::abs(cutoffHz - voice.cachedFilterCutoffHz) > 0.5f ||
            std::abs(q - voice.cachedFilterQ) > 0.001f) {
            cookSamplerBiquad(voice.cachedFilterCoeffs, 0,
                              static_cast<float>(sampleRate), cutoffHz, q);
            voice.cachedFilterCutoffHz = cutoffHz;
            voice.cachedFilterQ = q;
            voice.cachedFilterMode = filterMode;
        }
        float out = processBiquadSample(sample, voice.cachedFilterCoeffs, voice.filterState);
        out = processBiquadSample(out, voice.cachedFilterCoeffs, voice.filterState2);
        return out;
    }

    // Standard biquad
    if (filterMode != voice.cachedFilterMode ||
        std::abs(cutoffHz - voice.cachedFilterCutoffHz) > 0.5f ||
        std::abs(q - voice.cachedFilterQ) > 0.001f) {
        cookSamplerBiquad(voice.cachedFilterCoeffs, filterMode,
                          static_cast<float>(sampleRate), cutoffHz, q);
        voice.cachedFilterCutoffHz = cutoffHz;
        voice.cachedFilterQ = q;
        voice.cachedFilterMode = filterMode;
    }
    return processBiquadSample(sample, voice.cachedFilterCoeffs, voice.filterState);
}

} // anonymous namespace

// -----------------------------------------------------------------------
// Public helper functions
// -----------------------------------------------------------------------

int phaseModUnisonCount(float normalized) noexcept {
    const float clamped = safe_clamp(normalized, 0.0f, 1.0f);
    return 1 + static_cast<int>(std::lround(clamped * static_cast<float>(kPhaseModMaxUnison - 1)));
}

float phaseModRatioNormToValue(float norm) noexcept {
    constexpr float ratios[] = {0.5f, 1.0f, 1.5f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 8.0f};
    constexpr int count = static_cast<int>(sizeof(ratios) / sizeof(ratios[0]));
    const int idx = std::clamp(static_cast<int>(std::lround(norm * static_cast<float>(count - 1))), 0, count - 1);
    return ratios[idx];
}

float phaseModFineNormToCents(float norm) noexcept {
    return (norm - 0.5f) * 100.0f;
}

float phaseModOpHz(int rootPitch, float ratio, float fineCents) noexcept {
    const float baseHz = midiNoteToHz(rootPitch);
    return baseHz * ratio * std::pow(2.0f, fineCents / 1200.0f);
}

// -----------------------------------------------------------------------
// Per-voice sample renderer
// -----------------------------------------------------------------------

float phaseModVoiceSample(PhaseModSynthVoiceRuntime& voice,
                          const PhaseModSynthParams& params,
                          float ampGain,
                          float filterGain,
                          double sampleRate,
                          float glideCoeff,
                          float lfoOut) noexcept {
    const int effectivePitch = voice.pitch;
    const float glideTargetHz = midiNoteToHz(effectivePitch);
    if (glideCoeff > 0.0f && glideCoeff < 1.0f) {
        voice.currentHz += (glideTargetHz - voice.currentHz) * glideCoeff;
    } else {
        voice.currentHz = glideTargetHz;
    }
    voice.targetHz = glideTargetHz;

    const float rootHz = voice.currentHz;
    const int unisonCount = phaseModUnisonCount(params.unisonVoices);
    const float spreadCents = params.unisonDetune * 50.0f;

    if (unisonCount != voice.cachedUnisonCount ||
        std::abs(spreadCents - voice.cachedUnisonSpreadCents) > 0.01f) {
        precomputePhaseIncs(voice.opPhaseIncs, unisonCount, spreadCents, sampleRate);
        voice.cachedUnisonCount = unisonCount;
        voice.cachedUnisonSpreadCents = spreadCents;
    }

    float lfoPitchMod = 0.0f;
    if (params.lfoDest == 1 && params.lfoAmount > 0.0f) {
        lfoPitchMod = lfoOut * params.lfoAmount * 12.0f;
    }

    float opHz[kPhaseModOpsPerVoice];
    for (int op = 0; op < kPhaseModOpsPerVoice; ++op) {
        const auto& opParams = params.operators[op];
        const float ratio = opParams.ratio <= 0.0f ? 1.0f : opParams.ratio;
        opHz[op] = rootHz * ratio * std::pow(2.0f, opParams.fine / 1200.0f);
        if (lfoPitchMod != 0.0f) {
            opHz[op] *= std::pow(2.0f, lfoPitchMod / 1200.0f);
        }
    }

    // Ops serial (same-sample PM); unison parallel via SIMD bank.
    // Layout: modOutput/opOutput[u * ops + op], phases interleaved same way.
    float modOutput[kPhaseModMaxUnison * kPhaseModOpsPerVoice]{};
    float opOutput[kPhaseModMaxUnison * kPhaseModOpsPerVoice]{};

    for (int opIdx = 0; opIdx < kPhaseModOpsPerVoice; ++opIdx) {
        const auto& opParams = params.operators[opIdx];
        float phaseLanes[kPhaseModMaxUnison]{};
        float incLanes[kPhaseModMaxUnison]{};
        float modPhases[kPhaseModMaxUnison]{};
        float outLanes[kPhaseModMaxUnison]{};

        for (int u = 0; u < unisonCount; ++u) {
            const int phaseIdx = u * kPhaseModOpsPerVoice + opIdx;
            phaseLanes[u] = voice.opPhases[phaseIdx];
            incLanes[u] = voice.opPhaseIncs[phaseIdx];

            float modPhase = 0.0f;
            for (int srcOp = 0; srcOp < kPhaseModOpsPerVoice; ++srcOp) {
                const auto& srcParams = params.operators[srcOp];
                float influence = 0.0f;
                if (opIdx == 0)      influence = srcParams.attack;
                else if (opIdx == 1) influence = srcParams.decay;
                else if (opIdx == 2) influence = srcParams.sustain;
                else                 influence = srcParams.release;

                if (influence > 0.0f) {
                    const int srcIdx = u * kPhaseModOpsPerVoice + srcOp;
                    const float modulatorSample = (srcOp >= opIdx)
                        ? voice.prevOpOutput[srcIdx]
                        : modOutput[srcIdx];
                    modPhase += modulatorSample * influence * 4.0f;
                }
            }
            // Wire unused feedback param as self-mod on op0 (previous sample).
            if (opIdx == 0 && params.feedback > 0.0f) {
                const int selfIdx = u * kPhaseModOpsPerVoice;
                modPhase += voice.prevOpOutput[selfIdx] * params.feedback * 4.0f;
            }
            modPhases[u] = modPhase;
        }

        if (!renderPhaseModUnisonOpSimd(opParams.wave,
                                        opParams.level,
                                        opHz[opIdx],
                                        incLanes,
                                        phaseLanes,
                                        modPhases,
                                        unisonCount,
                                        outLanes)) {
            for (int u = 0; u < unisonCount; ++u) {
                phaseLanes[u] += opHz[opIdx] * incLanes[u];
                if (phaseLanes[u] >= kPM_TwoPi) {
                    phaseLanes[u] -= kPM_TwoPi;
                }
                outLanes[u] = pmMorphWaveSample(opParams.wave, phaseLanes[u] + modPhases[u]) *
                              opParams.level;
            }
        }

        for (int u = 0; u < unisonCount; ++u) {
            const int phaseIdx = u * kPhaseModOpsPerVoice + opIdx;
            voice.opPhases[phaseIdx] = phaseLanes[u];
            modOutput[phaseIdx] = outLanes[u];
            opOutput[phaseIdx] = outLanes[u];
            voice.prevOpOutput[phaseIdx] = std::tanh(outLanes[u]);
        }
    }

    (void)params.algoIndex; // matrix routing is source of truth; algos reserved

    float mixAccum = 0.0f;
    for (int u = 0; u < unisonCount; ++u) {
        const int base = u * kPhaseModOpsPerVoice;
        mixAccum += (opOutput[base] + opOutput[base + 1] + opOutput[base + 2] +
                     opOutput[base + 3]) *
                    0.25f;
    }

    float output = mixAccum / static_cast<float>(unisonCount);
    output = pmProcessFilter(output, voice, params, filterGain, static_cast<float>(sampleRate));
    output = std::tanh(output * 0.75f) / 0.75f;
    output *= ampGain;
    return output;
}

// -----------------------------------------------------------------------
// Live voice renderer
// -----------------------------------------------------------------------

void renderPhaseModLiveVoice(float& mix,
                             PhaseModSynthVoiceRuntime& voice,
                             const PhaseModSynthParams& params,
                             double sampleRate,
                             double elapsedSec,
                             double noteDurationSec) noexcept {
    if (voice.active == 0) {
        return;
    }
    if (elapsedSec < 0.0) {
        return;
    }

    const float ampAttackSec = adsrNormalizedToSeconds(params.ampAttack, 2.0f);
    const float ampDecaySec = adsrNormalizedToSeconds(params.ampDecay, 2.0f);
    const float ampReleaseSec = adsrNormalizedToSeconds(params.ampRelease, 3.0f);
    const float ampSustain = safe_clamp(params.ampSustain, 0.0f, 1.0f);

    const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
    const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
    const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
    const float filterSustain = safe_clamp(params.filterSustain, 0.0f, 1.0f);

    const float ampGain = samplerAdsrGain(static_cast<float>(elapsedSec),
                                          static_cast<float>(noteDurationSec),
                                          ampAttackSec,
                                          ampDecaySec,
                                          ampSustain,
                                          ampReleaseSec);
    if (ampGain <= 0.0f) {
        if (noteDurationSec < 3600.0) {
            voice.active = 0;
        }
        return;
    }

    const float filterGain = samplerAdsrGain(static_cast<float>(elapsedSec),
                                             static_cast<float>(noteDurationSec),
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

    // For live voice, LFO is computed by the caller and modulated into params
    // before calling this function. We pass zero LFO here and rely on the
    // caller applying LFO modulation to the params struct.
    mix += phaseModVoiceSample(voice, params,
                               ampGain * velGain,
                               filterGain,
                               sampleRate, glideCoeff, 0.0f) *
           params.gain * kInstrumentOutputGain * params.masterVol;
}

} // namespace audioapp