#include "audioapp/SubtractiveSynth.hpp"

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

float applyFilterShaper(float sample, int mode, float amount) noexcept {
    const float amt = std::clamp(amount, 0.0f, 1.0f);
    const int shaperMode = std::clamp(mode, 0, 3);
    if (amt <= 0.0f || shaperMode == 0) {
        return sample;
    }

    float shaped = sample;
    switch (shaperMode) {
    case 1:
        shaped = std::tanh(sample * 2.5f);
        break;
    case 2:
        shaped = std::clamp(sample * 3.0f, -1.0f, 1.0f);
        break;
    case 3:
        shaped = std::sin(sample * kPi * 1.5f);
        break;
    default:
        break;
    }
    return sample * (1.0f - amt) + shaped * amt;
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

/// Per-frame LFO modulation for the subtractive synth's DSP params.
/// Mirrors the applyModulation(SubtractiveSynthParams&, ...) overload in
/// DeviceChain.cpp's audio thread (kept local so the audio thread doesn't
/// need to know about the variant dispatch). The DeviceChain variant is the
/// source of truth; keep these in sync when adding new params.
static void applySubtractiveModulation(SubtractiveSynthParams& p, float modAmount, uint16_t localParamId) noexcept {
    switch (static_cast<SubtractiveParam>(unpackParamId(localParamId))) {
    case SubtractiveParam::FilterCutoff:      p.filterCutoff = std::clamp(p.filterCutoff + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterQ:           p.filterQ = std::clamp(p.filterQ + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterMode:        p.filterMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.filterMode) + modAmount * 5.0f)), 0, 5); break;
    case SubtractiveParam::AmpAttack:         p.ampAttack = std::clamp(p.ampAttack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpDecay:          p.ampDecay = std::clamp(p.ampDecay + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpSustain:        p.ampSustain = std::clamp(p.ampSustain + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::AmpRelease:        p.ampRelease = std::clamp(p.ampRelease + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Shape:         p.osc1Shape = std::clamp(p.osc1Shape + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Shape:         p.osc2Shape = std::clamp(p.osc2Shape + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Octave:        p.osc1Octave = std::clamp(p.osc1Octave + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Semi:          p.osc1Semi = std::clamp(p.osc1Semi + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc1Detune:        p.osc1Detune = std::clamp(p.osc1Detune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Octave:        p.osc2Octave = std::clamp(p.osc2Octave + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Semi:          p.osc2Semi = std::clamp(p.osc2Semi + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Detune:        p.osc2Detune = std::clamp(p.osc2Detune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::OscMix:            p.oscMix = std::clamp(p.oscMix + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::OscMixMode:        p.oscMixMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.oscMixMode) + modAmount * 4.0f)), 0, 4); break;
    case SubtractiveParam::Osc1Sync:          p.osc1Sync = std::clamp(p.osc1Sync + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::Osc2Sync:          p.osc2Sync = std::clamp(p.osc2Sync + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::NoiseLevel:        p.noiseLevel = std::clamp(p.noiseLevel + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::UnisonVoices:      p.unisonVoices = std::clamp(p.unisonVoices + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::UnisonDetune:      p.unisonDetune = std::clamp(p.unisonDetune + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterEnvAmount:   p.filterEnvAmount = std::clamp(p.filterEnvAmount + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterAttack:      p.filterAttack = std::clamp(p.filterAttack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterDecay:       p.filterDecay = std::clamp(p.filterDecay + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterSustain:     p.filterSustain = std::clamp(p.filterSustain + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterRelease:     p.filterRelease = std::clamp(p.filterRelease + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::GlideMs:           p.glideMs = std::clamp(p.glideMs + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::VelocitySensitivity: p.velocitySensitivity = std::clamp(p.velocitySensitivity + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreHpCutoff:       p.preHpCutoff = std::clamp(p.preHpCutoff + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreHpRes:          p.preHpRes = std::clamp(p.preHpRes + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::PreDrive:          p.preDrive = std::clamp(p.preDrive + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::MixFeedback:       p.mixFeedback = std::clamp(p.mixFeedback + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::GlobalPitch:       p.globalPitch = std::clamp(p.globalPitch + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterKeyTrack:    p.filterKeyTrack = std::clamp(p.filterKeyTrack + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterDrive:       p.filterDrive = std::clamp(p.filterDrive + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterShaper:      p.filterShaper = std::clamp(p.filterShaper + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterFm:          p.filterFm = std::clamp(p.filterFm + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::FilterShaperMode:  p.filterShaperMode = std::clamp(static_cast<int>(std::lround(static_cast<float>(p.filterShaperMode) + modAmount * 3.0f)), 0, 3); break;
    case SubtractiveParam::SynthLegato:       p.synthLegato = std::clamp(p.synthLegato + modAmount, 0.0f, 1.0f); break;
    case SubtractiveParam::SynthMono:         p.synthMono = std::clamp(p.synthMono + modAmount, 0.0f, 1.0f); break;
    default: break;
    }
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

    const float sync = std::clamp(syncAmount, 0.0f, 1.0f);
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

    const float mix = std::clamp(params.oscMix, 0.0f, 1.0f);

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
        std::clamp(params.osc1Sync, 0.0f, 1.0f) * std::clamp(params.osc2Sync, 0.0f, 1.0f);
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

    const float fbAmt = std::clamp(params.mixFeedback, 0.0f, 1.0f) * 0.35f;
    if (fbAmt > 0.0f) {
        mixed += std::tanh(voice.mixFeedbackSample) * fbAmt;
    }

    const float preDrive = std::clamp(params.preDrive, 0.0f, 1.0f);
    if (preDrive > 0.0f) {
        mixed *= 1.0f + preDrive * 5.0f;
        mixed = std::tanh(mixed);
    }

    const float preHpCut = std::clamp(params.preHpCutoff, 0.0f, 1.0f);
    if (preHpCut > 0.02f) {
        const float q = normalizedQToValue(std::clamp(params.preHpRes, 0.0f, 1.0f));
        const float hpCutoffHz = std::clamp(normalizedCutoffToHz(preHpCut), 20.0f, 20000.0f);
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
    const float filterFm = std::clamp(params.filterFm, 0.0f, 1.0f);
    if (filterFm > 0.0f) {
        const float fmMod = 1.0f + filterFm * osc2 * 3.0f;
        envCutoff *= std::clamp(fmMod, 0.2f, 4.0f);
    }
    const float keyTrack = std::clamp(params.filterKeyTrack, 0.0f, 1.0f);
    const float semitonesFromRef = static_cast<float>(effectivePitch - 60);
    const float keyTrackRatio = std::pow(2.0f, semitonesFromRef * keyTrack / 12.0f);
    const float cutoffHz =
        std::clamp(envCutoff * keyTrackRatio, 20.0f, 20000.0f);
    const int filterMode = std::clamp(params.filterMode, 0, 5);
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

    const float filterDrive = std::clamp(params.filterDrive, 0.0f, 1.0f);
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
                                  SubtractiveSynthRuntime& runtime,
                                  const AutomationClipPlayback* automationClips,
                                  int automationClipCount,
                                  const uint16_t* automationDeviceIndex,
                                  const float* lfoValues,
                                  int lfoCount,
                                  int lfoStride,
                                  const ModulationEdgePlayback* modEdges,
                                  int modEdgeCount,
                                  const uint16_t* modulationDeviceIndex) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const bool useAutomation = automationClips != nullptr && automationClipCount > 0 &&
                               automationDeviceIndex != nullptr;
    const bool useModulation = lfoValues != nullptr && lfoCount > 0 && lfoStride > 0 &&
                               modEdges != nullptr && modEdgeCount > 0 &&
                               modulationDeviceIndex != nullptr;

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

    // --- Phase 1: Voice allocation — ensure a runtime voice exists for each unique pitch ---
    int allocatedVoices = 0;

    for (int ni = 0; ni < noteCount && allocatedVoices < kSubtractiveMaxVoices; ++ni) {
        // Find or create a runtime voice slot for this note
        int vi = -1;
        // 1. Exact match by pitch
        for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
            if (runtime.voices[v].active != 0 &&
                runtime.voices[v].pitch == notes[ni].pitch) {
                vi = v;
                break;
            }
        }
        // 2. Free slot
        if (vi < 0) {
            for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
                if (runtime.voices[v].active == 0) { vi = v; break; }
            }
        }
        // 3. Steal
        if (vi < 0) {
            vi = runtime.stealIndex;
            runtime.stealIndex = (runtime.stealIndex + 1) % kSubtractiveMaxVoices;
        }

        auto& voice = runtime.voices[vi];
        if (voice.pitch != notes[ni].pitch) {
            std::memset(&voice, 0, sizeof(voice));
            voice.active = 1;
            voice.pitch = notes[ni].pitch;
            voice.velocity = notes[ni].velocity;
            voice.targetHz = subtractiveOscPitchHz(notes[ni].pitch, 0.5f, 0.0f, 0.5f);
            voice.currentHz = voice.targetHz;
            voice.noiseSeed = 0.1f + static_cast<float>(notes[ni].pitch) * 0.013f;
        } else {
            voice.active = 1; // keep alive
        }

        ++allocatedVoices;
    }

    // Leave all active voices alone — release tails play naturally via per-frame ADSR.
    if (allocatedVoices == 0) return;

    // Mono mode: keep only the voice for the last allocated pitch
    if (params.synthMono >= 0.5f && allocatedVoices > 1) {
        // Find the voice matching the last note in the list
        int lastPitch = -1;
        for (int ni = noteCount - 1; ni >= 0; --ni) {
            for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
                if (runtime.voices[v].active != 0 && runtime.voices[v].pitch == notes[ni].pitch) {
                    lastPitch = notes[ni].pitch;
                    break;
                }
            }
            if (lastPitch >= 0) break;
        }
        for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
            if (runtime.voices[v].active != 0 && runtime.voices[v].pitch != lastPitch) {
                runtime.voices[v].active = 0;
            }
        }
    }

    // --- Phase 2: Per-frame rendering ---
    // Render ALL active voices each frame, matching each to its note by pitch.
    // Notes are still in notes[] even after their end, allowing release tails to play.
    for (int frame = 0; frame < numFrames; ++frame) {
        const double beat = beatAtFrame(blockStartBeat, frame, sampleRate, bpm);

        SubtractiveSynthParams frameParams = params;
        if (useAutomation) {
            DeviceVariantParams variant = frameParams;
            applyDspAutomationAtBeat(variant,
                                     DeviceNodeKind::SubtractiveSynth,
                                     *automationDeviceIndex,
                                     beat,
                                     automationClips,
                                     automationClipCount);
            if (const auto* automated = std::get_if<SubtractiveSynthParams>(&variant)) {
                frameParams = *automated;
            }
        }
        if (useModulation) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const ModulationEdgePlayback& edge = modEdges[e];
                if (edge.deviceIndex != *modulationDeviceIndex) continue;
                if (edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == kEncodedCommonGain ||
                    pid == kEncodedCommonPan) {
                    continue;
                }
                const float lfoOut = lfoValues[static_cast<size_t>(edge.lfoId) *
                                                  static_cast<size_t>(lfoStride) +
                                                  static_cast<size_t>(frame)];
                const float modAmount = edge.amount * lfoOut;
                applySubtractiveModulation(frameParams, modAmount, pid);
            }
        }

        float mix = 0.0f;
        int renderedCount = 0;
        for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
            auto& voice = runtime.voices[v];
            if (voice.active == 0) continue;

            // Find matching note region by pitch
            int ni = -1;
            for (int n = 0; n < noteCount; ++n) {
                if (notes[n].pitch == voice.pitch) { ni = n; break; }
            }
            if (ni < 0) continue;

            const auto& note = notes[ni];
            double elapsedSec = 0.0, noteDurSec = 0.0;
            bool inRelease = false;
            if (!isSubtractiveNoteAudible(note, beat, bpm, ampReleaseSec,
                                           elapsedSec, noteDurSec, inRelease)) {
                if (inRelease && elapsedSec >= noteDurSec + static_cast<double>(ampReleaseSec)) {
                    voice.active = 0;
                }
                continue;
            }

            const float ampGain = samplerAdsrGain(static_cast<float>(elapsedSec),
                                                  static_cast<float>(noteDurSec),
                                                  ampAttackSec, ampDecaySec,
                                                  ampSustain, ampReleaseSec);
            if (ampGain <= 0.0f) {
                if (inRelease && elapsedSec >= noteDurSec + static_cast<double>(ampReleaseSec)) {
                    voice.active = 0;
                }
                continue;
            }

            const float filterGain = samplerAdsrGain(static_cast<float>(elapsedSec),
                                                     static_cast<float>(noteDurSec),
                                                     filterAttackSec, filterDecaySec,
                                                     filterSustain, filterReleaseSec);
            const float vel = std::clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
            const float velGain = 1.0f - frameParams.velocitySensitivity * (1.0f - vel);

            mix += subtractiveVoiceSample(voice, frameParams,
                                           ampGain * velGain,
                                           filterGain,
                                           sampleRate, glideCoeff) *
                   frameParams.gain * kInstrumentOutputGain;

            if (inRelease && elapsedSec >= noteDurSec + static_cast<double>(ampReleaseSec)) {
                voice.active = 0;
            }

            ++renderedCount;
        }

        if (renderedCount > 0) {
            mix *= 1.0f / std::sqrt(static_cast<float>(renderedCount));
        }

        monoOut[frame] += mix;
    }
}

} // namespace audioapp
