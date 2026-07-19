#pragma once

#include <cstdint>

#include "audioapp/AutomationTypes.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/dsp/CommonControlBlock.hpp"

namespace audioapp {

static constexpr int kWavetableMaxVoices = 8;
static constexpr int kWavetableMaxUnison = 8;

struct WavetableSynthParams {
    float gain = 1.0f;
    std::string wavetableId;
    // Resolved on the control thread for realtime playback.
    int wavetableIndex = -1;
    float wtPosition = 0.0f;
    float wtOctave = 0.5f;
    float wtSemitone = 0.5f;
    float wtFine = 0.5f;
    float wtUnison = 0.0f;
    float wtDetune = 0.0f;
    int filterMode = 0;
    float filterCutoff = 1.0f;
    float filterResonance = 0.0f;
    float filterEnvAmount = 0.0f;
    float filterAttack = 0.1f;
    float filterDecay = 0.3f;
    float filterSustain = 0.5f;
    float filterRelease = 0.5f;
    float ampAttack = 0.01f;
    float ampDecay = 0.2f;
    float ampSustain = 0.8f;
    float ampRelease = 0.3f;
};

struct WavetableSynthParamsPlayback {
    float gain = 1.0f;
    int wavetableIndex = -1;
    float wtPosition = 0.0f;
    float wtOctave = 0.5f;
    float wtSemitone = 0.5f;
    float wtFine = 0.5f;
    float wtUnison = 0.0f;
    float wtDetune = 0.0f;
    int filterMode = 0;
    float filterCutoff = 1.0f;
    float filterResonance = 0.0f;
    float filterEnvAmount = 0.0f;
    float filterAttack = 0.1f;
    float filterDecay = 0.3f;
    float filterSustain = 0.5f;
    float filterRelease = 0.5f;
    float ampAttack = 0.01f;
    float ampDecay = 0.2f;
    float ampSustain = 0.8f;
    float ampRelease = 0.3f;
};

/// Strip control-thread asset identity when copying parameters in realtime.
/// The audio snapshot resolves `wavetableIndex`; DSP never needs to copy the
/// potentially heap-backed asset name.
inline WavetableSynthParamsPlayback wavetableRealtimeParams(
    const WavetableSynthParams& source) noexcept {
    WavetableSynthParamsPlayback out;
    out.gain = source.gain;
    out.wavetableIndex = source.wavetableIndex;
    out.wtPosition = source.wtPosition;
    out.wtOctave = source.wtOctave;
    out.wtSemitone = source.wtSemitone;
    out.wtFine = source.wtFine;
    out.wtUnison = source.wtUnison;
    out.wtDetune = source.wtDetune;
    out.filterMode = source.filterMode;
    out.filterCutoff = source.filterCutoff;
    out.filterResonance = source.filterResonance;
    out.filterEnvAmount = source.filterEnvAmount;
    out.filterAttack = source.filterAttack;
    out.filterDecay = source.filterDecay;
    out.filterSustain = source.filterSustain;
    out.filterRelease = source.filterRelease;
    out.ampAttack = source.ampAttack;
    out.ampDecay = source.ampDecay;
    out.ampSustain = source.ampSustain;
    out.ampRelease = source.ampRelease;
    return out;
}

inline WavetableSynthParamsPlayback wavetableRealtimeParams(
    const WavetableSynthParamsPlayback& source) noexcept {
    return source;
}

struct WavetableVoiceRuntime {
    uint8_t active = 0;
    int pitch = 60;
    int noteKey = -1;
    float velocity = 100.0f;
    double startBeat = 0.0;
    double clipStartBeat = 0.0;
    double releaseBeat = -1.0;
    float phases[kWavetableMaxUnison]{};
    float unisonHzRatio[kWavetableMaxUnison]{1.0f, 1.0f, 1.0f, 1.0f,
                                            1.0f, 1.0f, 1.0f, 1.0f};
    int cachedUnisonCount = 0;
    float cachedUnisonSpreadCents = -1.0f;
    float targetHz = 440.0f;
    float currentHz = 440.0f;
    float wtFrameIndex = 0.0f;
    BiquadCoeffs cachedFilterCoeffs{};
    float cachedFilterCutoffHz = -1.0f;
    float cachedFilterQ = -1.0f;
    int cachedFilterMode = -1;
    float smoothCutoffHz = -1.0f;
    BiquadState filterState{};
    BiquadState filterState2{};
};

struct WavetableSynthRuntime {
    WavetableVoiceRuntime voices[kWavetableMaxVoices]{};
    int stealIndex = 0;
    /// Smoothed normalized wavetable position used to avoid zipper/clicks when
    /// UI or automation changes the position during playback.
    float smoothedWtPosition = 0.0f;
    uint8_t wtPositionSmoothingInitialized = 0;
    /// Index into WavetableBank (-1 = default)
    int wavetableIndex = -1;
};

struct InstrumentModulationContext;

struct WavetableMidiNoteRegion {
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

void mixWavetableMidiNotesBlock(float* monoOut,
                                int numFrames,
                                double sampleRate,
                                int bpm,
                                double playheadStartBeat,
                                const WavetableMidiNoteRegion* notes,
                                int noteCount,
                                const WavetableSynthParamsPlayback& params,
                                WavetableSynthRuntime& runtime,
                                const float* wavetablePcm,
                                int wavetableFrameCount,
                                int wavetableFrameLength,
                                const AutomationClipPlayback* automationClips = nullptr,
                                int automationClipCount = 0,
                                const uint16_t* automationDeviceIndex = nullptr,
                                const float* lfoValues = nullptr,
                                int lfoCount = 0,
                                int lfoStride = 0,
                                const ModulationEdgePlayback* modEdges = nullptr,
                                int modEdgeCount = 0,
                                const uint16_t* modulationDeviceIndex = nullptr,
                                const float* perFramePanelGain = nullptr,
                                const InstrumentModulationContext* instMod = nullptr,
                                int voiceLimit = kWavetableMaxVoices,
                                bool retriggerReplacesVoice = false,
                                const CommonControlBlock* commonControls = nullptr) noexcept;

float wavetableInterpolatedSample(const float* table,
                                  int frameCount,
                                  int frameLength,
                                  float frameIndex,
                                  float phase) noexcept;

int wavetableUnisonCount(float normalized) noexcept;

float wavetablePitchHz(int rootPitch,
                       float octaveNorm,
                       float semiNorm,
                       float fineNorm) noexcept;

float wavetableVoiceSample(const WavetableSynthParamsPlayback& params,
                           const float* table,
                           int frameCount,
                           int frameLength,
                           WavetableVoiceRuntime& voice,
                           float wtPosition,
                           float sampleRate,
                           float ampGain,
                           float filterGain,
                           BiquadCoeffs& filterCoeffs,
                           BiquadState& filterState,
                           BiquadState& filterState2,
                           int filterMode,
                           float filterQ) noexcept;

} // namespace audioapp
