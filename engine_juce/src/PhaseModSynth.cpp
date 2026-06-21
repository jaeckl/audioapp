#include "audioapp/PhaseModSynth.hpp"

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

/// Check if a note is audible within a block (including release tail).
static bool isNoteAudibleInBlock(const PhaseModSynthMidiNoteRegion& note,
                                 double blockStartBeat,
                                 int numFrames,
                                 double sampleRate,
                                 int bpm,
                                 float releaseSec) noexcept {
    if (bpm <= 0 || sampleRate <= 0.0) return false;
    const double blockEndBeat = blockStartBeat + static_cast<double>(numFrames) *
        (static_cast<double>(bpm) / 60.0) / sampleRate;
    const double noteStart = note.clipStartBeat + note.noteStartBeat;
    const double noteEnd = noteStart + note.noteDurationBeats;
    const double releaseBeats = static_cast<double>(releaseSec) * static_cast<double>(bpm) / 60.0;
    const double totalEnd = noteEnd + releaseBeats;
    return !(blockEndBeat < noteStart || blockStartBeat >= totalEnd);
}

static bool isNoteAudible(const PhaseModSynthMidiNoteRegion& note,
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
    elapsedSecondsOut = elapsedBeats * 60.0 / static_cast<double>(bpm);
    noteDurationSecOut = note.noteDurationBeats * 60.0 / static_cast<double>(bpm);
    inReleaseOut = loopedBeat >= noteEnd;

    if (loopedBeat < noteEnd) {
        return true;
    }
    return loopedBeat < noteEnd + releaseBeats;
}

static float beatAtFrame(double playheadStartBeat, int frameIndex, double sampleRate, int bpm) {
    const double seconds = static_cast<double>(frameIndex) / sampleRate;
    return static_cast<float>(playheadStartBeat + seconds * static_cast<double>(bpm) / 60.0);
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
    // --- Glide ---
    const int effectivePitch = voice.pitch;
    const float glideTargetHz = midiNoteToHz(effectivePitch);
    if (glideCoeff > 0.0f && glideCoeff < 1.0f) {
        voice.currentHz += (glideTargetHz - voice.currentHz) * glideCoeff;
    } else {
        voice.currentHz = glideTargetHz;
    }
    voice.targetHz = glideTargetHz;

    const float rootHz = voice.currentHz;

    // --- Unison ---
    const int unisonCount = phaseModUnisonCount(params.unisonVoices);
    const float spreadCents = params.unisonDetune * 50.0f;

    // Refresh precomputed per-unison increments when unison count or detune changes
    if (unisonCount != voice.cachedUnisonCount) {
        precomputePhaseIncs(voice.opPhaseIncs, unisonCount, spreadCents, sampleRate);
        voice.cachedUnisonCount = unisonCount;
    }

    // --- LFO output for this sample ---
    // Apply LFO to pitch if destination is pitch
    float lfoPitchMod = 0.0f;
    if (params.lfoDest == 1 && params.lfoAmount > 0.0f) {
        lfoPitchMod = lfoOut * params.lfoAmount * 12.0f; // up to ±12 semitones
    }

    // --- Per-unison accumulator ---
    float mixAccum = 0.0f;

    for (int u = 0; u < unisonCount; ++u) {
        // Per-operator modulator outputs for the current unison voice
        float modOutput[kPhaseModOpsPerVoice]{};

        // Phase modulation contributions: modulators feed forward to carriers
        // First, accumulate operator outputs for this algorithm
        float opOutput[kPhaseModOpsPerVoice]{};

        // Precompute operator Hz (with pitch LFO applied uniformly)
        float opHz[kPhaseModOpsPerVoice];
        for (int op = 0; op < kPhaseModOpsPerVoice; ++op) {
            const auto& opParams = params.operators[op];
            const float fineCents = opParams.fine;
            const float ratio = opParams.ratio <= 0.0f ? 1.0f : opParams.ratio;
            opHz[op] = rootHz * ratio * std::pow(2.0f, fineCents / 1200.0f);

            // Apply LFO pitch modulation
            if (lfoPitchMod != 0.0f) {
                opHz[op] *= std::pow(2.0f, lfoPitchMod / 1200.0f);
            }
        }

        // Process operators in algorithm order
        const int algo = safe_clamp(params.algoIndex, 0, 7);

        // For each algorithm, determine processing order and modulation routing.
        // "modulators" feed their output into the phase of another operator.
        // "carriers" sum to the output mix.
        //
        // We process operators in topological order (modulators before their targets).
        // Algorithm table:
        //   0 (stack_4):       op1→op2→op3→op4 (all carriers)
        //   1 (mod_3_to_1):    op1→op2→op3, op4 carrier
        //   2 (mod_3_to_2):    op1→op2→op3, op4 carrier
        //   3 (dual_2_to_1):   op1→op2, op3→op4, 2+4 out
        //   4 (chain_4):       op1→op2→op3→op4 (op4 carrier)
        //   5 (pair_1_to_2):   op1→op2, op3→op4, 2+4 out
        //   6 (one_to_all):    op1→op2,3,4 all
        //   7 (all_mod_fb):    op1→op2→op3→op4, feedback on op1

        // Process all 4 operators sequentially with full 4x4 PM Matrix Modulation routing
        for (int opIdx = 0; opIdx < kPhaseModOpsPerVoice; ++opIdx) {
            const auto& opParams = params.operators[opIdx];
            const int phaseIdx = u * kPhaseModOpsPerVoice + opIdx;

            // Phase accumulation
            voice.opPhases[phaseIdx] += opHz[opIdx] * voice.opPhaseIncs[phaseIdx];
            if (voice.opPhases[phaseIdx] >= kPM_TwoPi) {
                voice.opPhases[phaseIdx] -= kPM_TwoPi;
            }

            float phase = voice.opPhases[phaseIdx];

            // 4x4 PM Matrix Modulation: Sum inputs from all 4 operators
            float modPhase = 0.0f;
            for (int srcOp = 0; srcOp < kPhaseModOpsPerVoice; ++srcOp) {
                const auto& srcParams = params.operators[srcOp];
                float influence = 0.0f;
                if (opIdx == 0)      influence = srcParams.attack;  // OP X -> OP 1
                else if (opIdx == 1) influence = srcParams.decay;   // OP X -> OP 2
                else if (opIdx == 2) influence = srcParams.sustain; // OP X -> OP 3
                else if (opIdx == 3) influence = srcParams.release; // OP X -> OP 4

                if (influence > 0.0f) {
                    // Forward modulation uses current-sample output; feedback/self-feedback uses previous-sample output
                    float modulatorSample = (srcOp >= opIdx) ? voice.prevOpOutput[srcOp] : modOutput[srcOp];
                    modPhase += modulatorSample * influence * 4.0f;
                }
            }

            phase += modPhase;

            // Read waveform
            float sample = pmMorphWaveSample(opParams.wave, phase);

            // Apply flat gate envelope (repurposed per-operator ADSR)
            sample *= opParams.level;

            modOutput[opIdx] = sample;
            opOutput[opIdx] = sample;
            voice.prevOpOutput[opIdx] = std::tanh(sample);
        }

        // Symmetrical output mix: all active operators sum to output
        float voiceSample = (opOutput[0] + opOutput[1] + opOutput[2] + opOutput[3]) * 0.25f;

        mixAccum += voiceSample;
    }

    // Scale unison sum
    float output = mixAccum / static_cast<float>(unisonCount);

    // --- Filter ---
    output = pmProcessFilter(output, voice, params, filterGain, sampleRate);

    // --- Soft clip before final output ---
    output = std::tanh(output * 0.75f) / 0.75f;

    // Apply amp gain
    output *= ampGain;

    return output;
}

// -----------------------------------------------------------------------
// Block renderer (sequencer / arrangement mode)
// -----------------------------------------------------------------------

void mixPhaseModMidiNotesBlock(float* monoOut,
                               int numFrames,
                               double sampleRate,
                               int bpm,
                               double playheadStartBeat,
                               const PhaseModSynthMidiNoteRegion* notes,
                               int noteCount,
                               const PhaseModSynthParams& params,
                               PhaseModSynthRuntime& runtime,
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
    const float ampSustain = safe_clamp(params.ampSustain, 0.0f, 1.0f);
    const float filterAttackSec = adsrNormalizedToSeconds(params.filterAttack, 2.0f);
    const float filterDecaySec = adsrNormalizedToSeconds(params.filterDecay, 2.0f);
    const float filterReleaseSec = adsrNormalizedToSeconds(params.filterRelease, 3.0f);
    const float filterSustain = safe_clamp(params.filterSustain, 0.0f, 1.0f);
    const float glideMs = params.glideMs * 2000.0f;
    const float glideCoeff =
        glideMs > 0.0f ? 1.0f - std::exp(-1.0f / (static_cast<float>(sampleRate) * glideMs * 0.001f))
                       : 1.0f;

    const double blockStartBeat = playheadStartBeat;

    // --- Phase 1: Voice allocation ---
    int allocatedVoices = 0;
    for (int ni = 0; ni < noteCount && allocatedVoices < kPhaseModMaxVoices; ++ni) {
        if (!isNoteAudibleInBlock(notes[ni], blockStartBeat, numFrames, sampleRate, bpm, ampReleaseSec)) {
            continue;
        }

        int vi = -1;
        // 1. Exact match by pitch and startBeat
        for (int v = 0; v < kPhaseModMaxVoices; ++v) {
            if (runtime.voices[v].active != 0 &&
                runtime.voices[v].pitch == notes[ni].pitch &&
                runtime.voices[v].startBeat == notes[ni].noteStartBeat) {
                vi = v;
                break;
            }
        }
        // 2. Free slot
        if (vi < 0) {
            for (int v = 0; v < kPhaseModMaxVoices; ++v) {
                if (runtime.voices[v].active == 0) { vi = v; break; }
            }
        }
        // 3. Steal
        if (vi < 0) {
            vi = runtime.stealIndex;
            runtime.stealIndex = (runtime.stealIndex + 1) % kPhaseModMaxVoices;
        }

        auto& voice = runtime.voices[vi];
        if (voice.pitch != notes[ni].pitch || voice.startBeat != notes[ni].noteStartBeat) {
            std::memset(&voice, 0, sizeof(voice));
            voice.active = 1;
            voice.pitch = notes[ni].pitch;
            voice.startBeat = notes[ni].noteStartBeat;
            voice.velocity = notes[ni].velocity;
            voice.targetHz = midiNoteToHz(notes[ni].pitch);
            voice.currentHz = voice.targetHz;
        } else {
            voice.active = 1;
        }
        ++allocatedVoices;
    }

    bool anyVoiceActive = false;
    for (int v = 0; v < kPhaseModMaxVoices; ++v) {
        if (runtime.voices[v].active != 0) {
            anyVoiceActive = true;
            break;
        }
    }
    if (!anyVoiceActive) return;

    // --- Per-frame rendering ---
    for (int frame = 0; frame < numFrames; ++frame) {
        const float beat = beatAtFrame(blockStartBeat, frame, sampleRate, bpm);

        PhaseModSynthParams frameParams = params;
        if (useAutomation) {
            DeviceVariantParams variant = frameParams;
            applyDspAutomationAtBeat(variant, DeviceNodeKind::PhaseModSynth,
                                     *automationDeviceIndex, beat,
                                     automationClips, automationClipCount);
            if (const auto* automated = std::get_if<PhaseModSynthParams>(&variant)) {
                frameParams = *automated;
            }
        }

        // Compute LFO output for this frame
        float lfoOut = 0.0f;
        if (useModulation) {
            for (int e = 0; e < modEdgeCount; ++e) {
                const ModulationEdgePlayback& edge = modEdges[e];
                if (edge.deviceIndex != *modulationDeviceIndex) continue;
                if (edge.lfoId >= static_cast<uint16_t>(lfoCount)) continue;
                const uint16_t pid = edge.localParamId;
                if (pid == kEncodedCommonGain || pid == kEncodedCommonPan) continue;
                lfoOut = lfoValues[static_cast<size_t>(edge.lfoId) *
                                   static_cast<size_t>(lfoStride) +
                                   static_cast<size_t>(frame)];
            }
        }

        float mix = 0.0f;
        int renderedCount = 0;

        // Mono mode
        int activeMonoPitch = -1;
        if (frameParams.synthMono >= 0.5f) {
            for (int ni = noteCount - 1; ni >= 0; --ni) {
                double elapsedSec = 0.0, noteDurSec = 0.0;
                bool inRelease = false;
                if (isNoteAudible(notes[ni], beat, bpm, ampReleaseSec,
                                  elapsedSec, noteDurSec, inRelease)) {
                    activeMonoPitch = notes[ni].pitch;
                    break;
                }
            }
        }

        for (int v = 0; v < kPhaseModMaxVoices; ++v) {
            auto& voice = runtime.voices[v];
            if (voice.active == 0) continue;

            if (frameParams.synthMono >= 0.5f && voice.pitch != activeMonoPitch) {
                if (activeMonoPitch >= 0) voice.active = 0;
                continue;
            }

            int ni = -1;
            for (int n = 0; n < noteCount; ++n) {
                if (notes[n].pitch == voice.pitch && notes[n].noteStartBeat == voice.startBeat) {
                    ni = n;
                    break;
                }
            }
            if (ni < 0) continue;

            const auto& note = notes[ni];
            double elapsedSec = 0.0, noteDurSec = 0.0;
            bool inRelease = false;
            if (!isNoteAudible(note, beat, bpm, ampReleaseSec,
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
            const float vel = safe_clamp(voice.velocity / 127.0f, 0.0f, 1.0f);
            const float velGain = 1.0f - frameParams.velocitySensitivity * (1.0f - vel);

            mix += phaseModVoiceSample(voice, frameParams,
                                       ampGain * velGain,
                                       filterGain,
                                       sampleRate, glideCoeff, lfoOut) *
                   frameParams.gain * kInstrumentOutputGain * frameParams.masterVol;

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
