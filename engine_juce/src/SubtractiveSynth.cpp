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

    const float osc1Root =
        subtractiveOscPitchHz(effectivePitch, params.osc1Octave, params.osc1Semi, params.osc1Detune);
    const float osc2Root =
        subtractiveOscPitchHz(effectivePitch, params.osc2Octave, params.osc2Semi, params.osc2Detune);
    const float pitchRatio =
        voice.currentHz / subtractiveOscPitchHz(effectivePitch, 0.5f, 0.0f, 0.5f);

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

    const float fbAmt = std::clamp(params.mixFeedback, 0.0f, 1.0f) * 0.7f;
    if (fbAmt > 0.0f) {
        mixed += voice.mixFeedbackSample * fbAmt;
    }

    const float preDrive = std::clamp(params.preDrive, 0.0f, 1.0f);
    if (preDrive > 0.0f) {
        mixed *= 1.0f + preDrive * 5.0f;
        mixed = std::tanh(mixed);
    }

    const float preHpCut = std::clamp(params.preHpCutoff, 0.0f, 1.0f);
    if (preHpCut > 0.02f) {
        const float hpCutoffHz = std::clamp(normalizedCutoffToHz(preHpCut), 20.0f, 20000.0f);
        BiquadCoeffs hpCoeffs{};
        cookSamplerBiquad(hpCoeffs,
                          1,
                          static_cast<float>(sampleRate),
                          hpCutoffHz,
                          normalizedQToValue(std::clamp(params.preHpRes, 0.0f, 1.0f)));
        mixed = processBiquadSample(mixed, hpCoeffs, voice.preHpState);
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
    if (filterMode == 4) {
        const int delaySamples = combDelaySamples(static_cast<float>(sampleRate), cutoffHz);
        const float feedback = 0.5f + normalizedQToValue(params.filterQ) * 0.06f;
        mixed = processCombSample(mixed, voice.combState, delaySamples, feedback);
    } else if (filterMode == 5) {
        BiquadCoeffs coeffs{};
        const float q = normalizedQToValue(params.filterQ);
        cookSamplerBiquad(coeffs, 0, static_cast<float>(sampleRate), cutoffHz, q);
        mixed = processBiquadSample(mixed, coeffs, voice.filterState);
        mixed = processBiquadSample(mixed, coeffs, voice.filterState2);
    } else {
        BiquadCoeffs coeffs{};
        cookSamplerBiquad(coeffs,
                          filterMode,
                          static_cast<float>(sampleRate),
                          cutoffHz,
                          normalizedQToValue(params.filterQ));
        mixed = processBiquadSample(mixed, coeffs, voice.filterState);
    }

    const float filterDrive = std::clamp(params.filterDrive, 0.0f, 1.0f);
    if (filterDrive > 0.0f) {
        mixed = std::tanh(mixed * (1.0f + filterDrive * 3.0f));
    }

    mixed = applyFilterShaper(mixed, params.filterShaperMode, params.filterShaper);

    voice.mixFeedbackSample = mixed;
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
                                  const uint16_t* automationDeviceIndex) noexcept {
    if (monoOut == nullptr || numFrames <= 0 || notes == nullptr || noteCount <= 0 || bpm <= 0) {
        return;
    }

    const bool useAutomation = automationClips != nullptr && automationClipCount > 0 &&
                               automationDeviceIndex != nullptr;

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

    // --- Phase 1: Voice binding (once per block, O(n) scan to find matching slots) ---
    // Check note overlap with the entire [blockStartBeat, blockEndBeat) range.
    const double blockEndBeat = blockStartBeat +
        static_cast<double>(numFrames) * 60.0 / (static_cast<double>(std::max(bpm, 1)) * sampleRate);
    int bindingToVoice[kSubtractiveMaxVoices];   // binding index → voice slot
    int boundNoteKey[kSubtractiveMaxVoices];
    int boundPitch[kSubtractiveMaxVoices];
    float boundVelocity[kSubtractiveMaxVoices];
    int boundNoteIdx[kSubtractiveMaxVoices];
    int bindingCount = 0;
    int stolenThisBlock = -1;

    for (int ni = 0; ni < noteCount && bindingCount < kSubtractiveMaxVoices; ++ni) {
        // Check if note is audible at any point in this block (sample midpoint as proxy)
        double es, nds;
        bool ir;
        const double probeBeat = blockStartBeat + (blockEndBeat - blockStartBeat) * 0.5;
        if (!isSubtractiveNoteAudible(notes[ni], probeBeat, bpm, ampReleaseSec, es, nds, ir)) {
            continue;
        }
        // Deduplicate by noteKey+pitch
        bool dup = false;
        for (int b = 0; b < bindingCount; ++b) {
            if (boundNoteKey[b] == notes[ni].noteKey && boundPitch[b] == notes[ni].pitch) {
                dup = true;
                break;
            }
        }
        if (dup) continue;

        // Find or create a runtime voice slot (same logic as original per-frame code)
        int vi = -1;
        // 1. Exact match
        for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
            if (runtime.voices[v].active != 0 &&
                runtime.voices[v].noteKey == notes[ni].noteKey &&
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
            stolenThisBlock = vi;
        }

        auto& voice = runtime.voices[vi];
        if (voice.active == 0 || voice.noteKey != notes[ni].noteKey || voice.pitch != notes[ni].pitch) {
            std::memset(&voice, 0, sizeof(voice));
            voice.active = 1;
            voice.pitch = notes[ni].pitch;
            voice.noteKey = notes[ni].noteKey;
            voice.velocity = notes[ni].velocity;
            voice.targetHz = subtractiveOscPitchHz(notes[ni].pitch, 0.5f, 0.0f, 0.5f);
            voice.currentHz = voice.targetHz;
            voice.noiseSeed = 0.1f + static_cast<float>(notes[ni].noteKey) * 0.013f;
        } else {
            voice.active = 1; // ensure not deactivated
        }

        bindingToVoice[bindingCount] = vi;
        boundNoteKey[bindingCount] = notes[ni].noteKey;
        boundPitch[bindingCount] = notes[ni].pitch;
        boundVelocity[bindingCount] = notes[ni].velocity;
        boundNoteIdx[bindingCount] = ni;
        ++bindingCount;
    }

    // Mono mode: keep only the last voice
    if (params.synthMono >= 0.5f && bindingCount > 1) {
        const int last = bindingCount - 1;
        for (int b = 0; b < last; ++b) {
            runtime.voices[bindingToVoice[b]].active = 0;
        }
        bindingToVoice[0] = bindingToVoice[last];
        boundNoteKey[0] = boundNoteKey[last];
        boundPitch[0] = boundPitch[last];
        boundVelocity[0] = boundVelocity[last];
        boundNoteIdx[0] = boundNoteIdx[last];
        bindingCount = 1;
    }

    // Deactivate any stray voices not in a binding
    for (int v = 0; v < kSubtractiveMaxVoices; ++v) {
        bool inUse = false;
        for (int b = 0; b < bindingCount; ++b) {
            if (bindingToVoice[b] == v) { inUse = true; break; }
        }
        if (!inUse) runtime.voices[v].active = 0;
    }

    if (bindingCount == 0) return;

    // --- Phase 2: Per-frame rendering with O(1) voice lookup via bindingToVoice ---
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

        float mix = 0.0f;
        for (int b = 0; b < bindingCount; ++b) {
            auto& voice = runtime.voices[bindingToVoice[b]];
            if (voice.active == 0) continue;

            const auto& note = notes[boundNoteIdx[b]];
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
            const float vel = std::clamp(boundVelocity[b] / 127.0f, 0.0f, 1.0f);
            const float velGain = 1.0f - frameParams.velocitySensitivity * (1.0f - vel);

            mix += subtractiveVoiceSample(voice, frameParams,
                                           ampGain * velGain,
                                           filterGain,
                                           sampleRate, glideCoeff) *
                   frameParams.gain * kInstrumentOutputGain;

            if (inRelease && elapsedSec >= noteDurSec + static_cast<double>(ampReleaseSec)) {
                voice.active = 0;
            }
        }

        monoOut[frame] += mix;
    }
}

} // namespace audioapp
