#pragma once

#include <cstdint>

#include "audioapp/SamplerFilter.hpp"
#include "audioapp/AutomationTypes.hpp"

namespace audioapp {

static constexpr int kPhaseModMaxVoices = 8;
static constexpr int kPhaseModMaxUnison = 4;
static constexpr int kPhaseModOpsPerVoice = 4;

/// Per-operator audio-thread parameters (flat struct, no heap).
struct PhaseModSynthOperatorParams {
    float ratio = 1.0f;       // actual ratio (0.5, 1, 1.5, 2, 3, 4, 5, 6, 8)
    float fine = 0.0f;        // detune in cents (-50..+50)
    float level = 0.0f;       // output level [0, 1]
    float wave = 0.0f;        // waveform morph [0, 1] sine->tri->saw->square->noise
    float attack = 0.01f;
    float decay = 0.3f;
    float sustain = 0.8f;
    float release = 0.4f;
    float velocitySense = 1.0f;
    float keyTrack = 0.0f;
};

/// Audio-thread params struct for the PM synth. All fields are value types.
struct PhaseModSynthParams {
    float gain = 1.0f;
    float masterVol = 0.85f;
    int algoIndex = 0;
    float feedback = 0.0f;
    PhaseModSynthOperatorParams operators[kPhaseModOpsPerVoice]{};

    // Filter
    int filterMode = 0;
    float filterCutoff = 0.85f;
    float filterQ = 0.25f;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    float filterKeyTrack = 0.0f;

    // Amp
    float ampAttack = 0.01f;
    float ampDecay = 0.3f;
    float ampSustain = 0.75f;
    float ampRelease = 0.35f;

    // Performance
    float glideMs = 0.0f;
    float velocitySensitivity = 1.0f;
    float unisonVoices = 0.0f;
    float unisonDetune = 0.15f;
    float synthMono = 0.0f;
    float synthLegato = 0.0f;

    // LFO
    float lfoRate = 0.2f;
    int lfoShape = 0;
    float lfoAmount = 0.0f;
    int lfoDest = 0;
    float vibratoDepth = 0.0f;
    float vibratoRate = 0.3f;
};

/// Per-voice runtime state for the PM synth (audio-thread only).
struct PhaseModSynthVoiceRuntime {
    uint8_t active = 0;
    int pitch = 60;
    int noteKey = -1;
    float velocity = 100.0f;
    double startBeat = 0.0;
    double releaseBeat = -1.0;

    // Per-operator phase accumulators.
    // For unison, indexed as [unisonVoice * kPhaseModOpsPerVoice + operatorIndex].
    // With kPhaseModMaxUnison=4 and kPhaseModOpsPerVoice=4, this is 16 floats.
    float opPhases[kPhaseModMaxUnison * kPhaseModOpsPerVoice]{};
    // Per-operator per-unison phase increments (precomputed before per-sample loop)
    float opPhaseIncs[kPhaseModMaxUnison * kPhaseModOpsPerVoice]{};
    int cachedUnisonCount = 0;
    // Cached key-track ratio (recomputed on note-on or param change)
    float cachedKeyTrackRatio = 1.0f;
    float envelopeValues[kPhaseModOpsPerVoice]{};
    int envelopePhase[kPhaseModOpsPerVoice]{};  // 0=attack,1=decay,2=sustain,3=release,4=done
    float envelopeStart[kPhaseModOpsPerVoice]{};
    float prevOpOutput[kPhaseModOpsPerVoice]{};  // previous sample output for feedback

    // Runtime state
    float currentHz = 440.0f;
    float targetHz = 440.0f;
    float currentPan = 0.5f;
    float lfoPhase = 0.0f;
    float smoothCutoffHz = -1.0f;
    float smoothQ = -1.0f;

    // Cached filter coefficients
    BiquadCoeffs cachedFilterCoeffs{};
    float cachedFilterCutoffHz = -1.0f;
    float cachedFilterQ = -1.0f;
    int cachedFilterMode = -1;
    BiquadState filterState{};
    BiquadState filterState2{};
    CombFilterState combFilterState{};
};

/// Voice pool (no heap allocation).
struct PhaseModSynthRuntime {
    PhaseModSynthVoiceRuntime voices[kPhaseModMaxVoices]{};
    int stealIndex = 0;
};

/// Midi note region for block rendering (matches SubtractiveMidiNoteRegion pattern).
struct PhaseModSynthMidiNoteRegion {
    int pitch = 60;
    int noteKey = 0;
    double clipStartBeat = 0.0;
    double clipLengthBeats = 4.0;
    double noteStartBeat = 0.0;
    double noteDurationBeats = 1.0;
    float velocity = 100.0f;
    bool loopContent = false;
    double contentLengthBeats = 4.0;
};

/// Direct-renderer entry point. Called by the arrangement playback path
/// (PhaseModSynthProcessor) and by tests/phase_mod_synth_test.cpp.
void mixPhaseModMidiNotesBlock(float* monoOut,
                               int numFrames,
                               double sampleRate,
                               int bpm,
                               double playheadStartBeat,
                               const PhaseModSynthMidiNoteRegion* notes,
                               int noteCount,
                               const PhaseModSynthParams& params,
                               PhaseModSynthRuntime& runtime,
                               const AutomationClipPlayback* automationClips = nullptr,
                               int automationClipCount = 0,
                               const uint16_t* automationDeviceIndex = nullptr,
                               const float* lfoValues = nullptr,
                               int lfoCount = 0,
                               int lfoStride = 0,
                               const ModulationEdgePlayback* modEdges = nullptr,
                               int modEdgeCount = 0,
                               const uint16_t* modulationDeviceIndex = nullptr) noexcept;

// -----------------------------------------------------------------------
// Helper functions
// -----------------------------------------------------------------------

/// Unison voice count from normalized [0,1] -> 1..kPhaseModMaxUnison.
int phaseModUnisonCount(float normalized) noexcept;

/// Ratio mapping from normalized [0,1] -> {0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0}.
float phaseModRatioNormToValue(float norm) noexcept;

/// Fine mapping: normalized [0,1] -> cents (-50..+50).
float phaseModFineNormToCents(float norm) noexcept;

/// Compute operator frequency in Hz from pitch + ratio + fine.
float phaseModOpHz(int rootPitch, float ratio, float fineCents) noexcept;

// -----------------------------------------------------------------------
// Per-voice sample rendering
// -----------------------------------------------------------------------

/// Render one sample for one voice.
/// Returns the mixed output sample after filter, amp, and FX.
float phaseModVoiceSample(PhaseModSynthVoiceRuntime& voice,
                          const PhaseModSynthParams& params,
                          float ampGain,
                          float filterGain,
                          double sampleRate,
                          float glideCoeff,
                          float lfoOut) noexcept;

// -----------------------------------------------------------------------
// Live voice renderer (live performance / instrument mode)
// -----------------------------------------------------------------------

void renderPhaseModLiveVoice(float& mix,
                             PhaseModSynthVoiceRuntime& voice,
                             const PhaseModSynthParams& params,
                             double sampleRate,
                             double elapsedSec,
                             double noteDurationSec) noexcept;

} // namespace audioapp