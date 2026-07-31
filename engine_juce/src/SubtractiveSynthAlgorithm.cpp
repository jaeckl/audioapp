#include "audioapp/SubtractiveSynthAlgorithm.hpp"

#include "audioapp/AutomationPlayback.hpp"
#include "audioapp/DeviceChain.hpp"
#include "audioapp/MidiUtils.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/SubtractiveMorphTable.hpp"
#include "audioapp/SubtractiveOscSimd.hpp"

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

/// Same soft-clip as BitcrusherProcessor — cheap stand-in for tanh.
static inline float softClip(float x) noexcept {
    return x / (1.0f + std::abs(x));
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
        shaped = softClip(sample * 2.5f);
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
                    float sampleRate,
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
    if (!hardSyncSlave) {
        float simdSum = 0.0f;
        if (renderOscBankNoSyncSimd(shape,
                                    rootHz,
                                    sampleRate,
                                    phaseIncPerUnit,
                                    unisonCount,
                                    level,
                                    phases,
                                    wrappedOut,
                                    simdSum)) {
            return simdSum;
        }
    }

    // Mip + morph frames once per osc bank; only phase index differs per unison.
    const auto& table = SubtractiveMorphTable::instance();
    const auto morph = table.prepareLookup(shape, table.pickMip(rootHz, sampleRate));

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
            sum += table.lookupPrepared(morph, phases[u]);
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

        const float hardSample = table.lookupPrepared(morph, phases[u]);
        const float freeSample = table.lookupPrepared(morph, freePhase);
        sum += hardSample * sync + freeSample * (1.0f - sync);
    }
    return (sum / static_cast<float>(unisonCount)) * level;
}

float subtractiveVoiceSample(SubtractiveVoiceRuntime& voice,
                  const SubtractiveSynthParams& params,
                  float ampGain,
                  float filterGain,
                  double sampleRate,
                  float glideCoeff,
                  bool refreshControlRate) noexcept {
    const int globalSemi =
        static_cast<int>(std::lround((params.globalPitch - 0.5f) * 24.0f));
    const int effectivePitch = voice.pitch + globalSemi;
    const float glideTargetHz =
        subtractiveOscPitchHz(effectivePitch, 0.5f, 0.0f, 0.5f);
    const bool gliding = glideCoeff > 0.0f && glideCoeff < 1.0f;
    if (gliding) {
        voice.currentHz += (glideTargetHz - voice.currentHz) * glideCoeff;
    } else {
        voice.currentHz = glideTargetHz;
    }
    voice.targetHz = glideTargetHz;

    const int unisonCount = subtractiveUnisonCount(params.unisonVoices);
    const float spreadCents = params.unisonDetune * 50.0f;

    // Refresh shared unison increments when unison count or detune changes.
    // Osc1/osc2 pitch offsets live in heldOsc*Hz, not this table.
    if (unisonCount != voice.cachedUnisonCount ||
        std::abs(spreadCents - voice.cachedUnisonSpreadCents) > 0.01f) {
        precomputeBankIncrements(voice.phaseIncPerUnit, unisonCount, 0.0f, spreadCents, sampleRate);
        voice.cachedUnisonCount = unisonCount;
        voice.cachedUnisonSpreadCents = spreadCents;
    }

    // Osc Hz: S&H at control rate when not gliding; glide stays sample-rate.
    const bool refreshPitch = refreshControlRate || gliding || !voice.controlPitchValid;
    if (refreshPitch) {
        const float osc1Root =
            subtractiveOscPitchHz(effectivePitch, params.osc1Octave, params.osc1Semi, params.osc1Detune);
        const float osc2Root =
            subtractiveOscPitchHz(effectivePitch, params.osc2Octave, params.osc2Semi, params.osc2Detune);
        const float pitchRatio =
            voice.currentHz / subtractiveOscPitchHz(effectivePitch, 0.5f, 0.0f, 0.5f);
        voice.heldOsc1Hz = osc1Root * pitchRatio;
        voice.heldOsc2Hz = osc2Root * pitchRatio;
        voice.controlPitchValid = !gliding;
    }

    const float mix = safe_clamp(params.oscMix, 0.0f, 1.0f);
    const float syncAmount =
        safe_clamp(params.osc1Sync, 0.0f, 1.0f) * safe_clamp(params.osc2Sync, 0.0f, 1.0f);
    const float filterFmEarly = safe_clamp(params.filterFm, 0.0f, 1.0f);
    constexpr float kMixEps = 1.0e-3f;
    // Linear mix (mode 0): mix≈0 → osc1 only; mix≈1 → osc2 only (unless hard-sync needs master).
    // Neg mix (mode 1): mix≈0 → osc1 only. AM/ring/max always need both.
    // Filter FM reads osc2 even when mix hides it.
    const bool needOsc2 =
        filterFmEarly > kMixEps ||
        !((params.oscMixMode == 0 || params.oscMixMode == 1) && mix <= kMixEps);
    const bool needOsc1 =
        !(params.oscMixMode == 0 && mix >= 1.0f - kMixEps && syncAmount <= kMixEps);

    bool osc1Wrapped[kSubtractiveMaxUnison]{};
    const float sr = static_cast<float>(sampleRate);
    float osc1 = 0.0f;
    if (needOsc1) {
        osc1 = renderOscBank(params.osc1Shape,
                             voice.heldOsc1Hz,
                             sr,
                             voice.phaseIncPerUnit,
                             unisonCount,
                             1.0f,
                             voice.osc1Phases,
                             needOsc2 && syncAmount > kMixEps ? osc1Wrapped : nullptr);
    } else {
        // Keep phase continuous if mix returns from osc2-only.
        for (int u = 0; u < unisonCount; ++u) {
            voice.osc1Phases[u] += voice.heldOsc1Hz * voice.phaseIncPerUnit[u];
            if (voice.osc1Phases[u] >= kSubtractiveTwoPi) {
                voice.osc1Phases[u] -= kSubtractiveTwoPi;
            }
        }
    }

    float osc2 = 0.0f;
    if (needOsc2) {
        osc2 = renderOscBank(params.osc2Shape,
                             voice.heldOsc2Hz,
                             sr,
                             voice.phaseIncPerUnit,
                             unisonCount,
                             1.0f,
                             voice.osc2Phases,
                             nullptr,
                             needOsc1 && syncAmount > kMixEps ? osc1Wrapped : nullptr,
                             voice.osc2FreePhases,
                             needOsc1 ? syncAmount : 0.0f);
    } else {
        for (int u = 0; u < unisonCount; ++u) {
            voice.osc2Phases[u] += voice.heldOsc2Hz * voice.phaseIncPerUnit[u];
            if (voice.osc2Phases[u] >= kSubtractiveTwoPi) {
                voice.osc2Phases[u] -= kSubtractiveTwoPi;
            }
            voice.osc2FreePhases[u] = voice.osc2Phases[u];
        }
    }

    float mixed = 0.0f;
    if (params.oscMixMode == 0) {
        if (!needOsc2) {
            mixed = osc1 * 0.7f;
        } else if (!needOsc1) {
            mixed = osc2 * 0.7f;
        } else {
            mixed = ((1.0f - mix) * osc1 + mix * osc2) * 0.7f;
        }
    } else {
        mixed = subtractiveMixOscPair(osc1, osc2, params.oscMixMode, mix) * 0.7f;
    }
    if (params.noiseLevel > 0.0f) {
        mixed += subtractiveNoiseSample(voice.noiseSeed) * params.noiseLevel * 0.25f;
    }

    const float fbAmt = safe_clamp(params.mixFeedback, 0.0f, 1.0f) * 0.35f;
    if (fbAmt > 0.0f) {
        mixed += softClip(voice.mixFeedbackSample) * fbAmt;
    }

    const float preDrive = safe_clamp(params.preDrive, 0.0f, 1.0f);
    if (preDrive > 0.0f) {
        mixed *= 1.0f + preDrive * 5.0f;
        mixed = softClip(mixed);
    }

    const float preHpCut = safe_clamp(params.preHpCutoff, 0.0f, 1.0f);
    if (preHpCut > 0.02f) {
        if (refreshControlRate) {
            const float q = normalizedQToValue(safe_clamp(params.preHpRes, 0.0f, 1.0f));
            const float hpCutoffHz = safe_clamp(normalizedCutoffToHz(preHpCut), 20.0f, 20000.0f);
            if (std::abs(hpCutoffHz - voice.cachedPreHpCutoffHz) > 0.5f ||
                std::abs(q - voice.cachedPreHpQ) > 0.001f) {
                cookSamplerBiquad(voice.cachedPreHpCoeffs, 1,
                                  static_cast<float>(sampleRate),
                                  hpCutoffHz, q);
                voice.cachedPreHpCutoffHz = hpCutoffHz;
                voice.cachedPreHpQ = q;
            }
        }
        mixed = processBiquadSample(mixed, voice.cachedPreHpCoeffs, voice.preHpState);
    }

    // Filter coeff cook: S&H @ control rate unless audio-rate filter FM is on.
    const float filterFm = safe_clamp(params.filterFm, 0.0f, 1.0f);
    const bool audioRateFilterFm = filterFm > 0.001f;
    const bool refreshFilter = refreshControlRate || audioRateFilterFm ||
                               voice.cachedFilterMode < 0;
    const int filterMode = safe_clamp(params.filterMode, 0, 5);
    const float rawQ = normalizedQToValue(params.filterQ);
    const float q = filterMode == 4 ? std::min(rawQ, 4.0f) : rawQ;

    if (refreshFilter) {
        const float baseCutoff = normalizedCutoffToHz(params.filterCutoff);
        float envCutoff = baseCutoff * (1.0f + filterGain * params.filterEnvAmount * 4.0f);
        if (audioRateFilterFm) {
            const float fmMod = 1.0f + filterFm * osc2 * 3.0f;
            envCutoff *= safe_clamp(fmMod, 0.2f, 4.0f);
        }
        const float keyTrack = safe_clamp(params.filterKeyTrack, 0.0f, 1.0f);
        const float semitonesFromRef = static_cast<float>(effectivePitch - 60);
        voice.cachedKeyTrackRatio = std::pow(2.0f, semitonesFromRef * keyTrack / 12.0f);
        const float rawCutoffHz =
            safe_clamp(envCutoff * voice.cachedKeyTrackRatio, 20.0f, 20000.0f);

        if (voice.smoothCutoffHz <= 0.0f) {
            voice.smoothCutoffHz = rawCutoffHz;
        } else if (audioRateFilterFm) {
            voice.smoothCutoffHz += (rawCutoffHz - voice.smoothCutoffHz) * 0.05f;
        } else {
            // Control-rate: snap toward held target (no per-sample smoothing tax).
            voice.smoothCutoffHz = rawCutoffHz;
        }
        const float cutoffHz = safe_clamp(voice.smoothCutoffHz, 20.0f, 20000.0f);

        if (filterMode == 4) {
            // Comb uses delay derived from cutoff; store cutoff so process path can read it.
            voice.cachedFilterCutoffHz = cutoffHz;
            voice.cachedFilterQ = q;
            voice.cachedFilterMode = filterMode;
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
        }
    }

    if (filterMode == 4) {
        const float cutoffHz = safe_clamp(voice.cachedFilterCutoffHz, 20.0f, 20000.0f);
        const int delaySamples = combDelaySamples(static_cast<float>(sampleRate), cutoffHz);
        const float feedback = std::min(0.88f, 0.45f + q * 0.08f);
        mixed = processCombSample(mixed, voice.combState, delaySamples, feedback);
    } else if (filterMode == 5) {
        mixed = processBiquadSample(mixed, voice.cachedFilterCoeffs, voice.filterState);
        mixed = processBiquadSample(mixed, voice.cachedFilterCoeffs, voice.filterState2);
    } else {
        mixed = processBiquadSample(mixed, voice.cachedFilterCoeffs, voice.filterState);
    }

    mixed = softClip(mixed * 0.75f) / 0.75f;

    const float filterDrive = safe_clamp(params.filterDrive, 0.0f, 1.0f);
    if (filterDrive > 0.0f) {
        mixed = softClip(mixed * (1.0f + filterDrive * 3.0f));
    }

    mixed = applyFilterShaper(mixed, params.filterShaperMode, params.filterShaper);

    voice.mixFeedbackSample = softClip(mixed);
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
    return SubtractiveMorphTable::instance().lookupMip(shape, phase, 0);
}

float subtractiveMorphWaveSample(float shape,
                                 float phase,
                                 float rootHz,
                                 float sampleRate) noexcept {
    return SubtractiveMorphTable::instance().lookup(shape, phase, rootHz, sampleRate);
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