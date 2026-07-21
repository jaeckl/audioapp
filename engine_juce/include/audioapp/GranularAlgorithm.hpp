#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/dsp/CommonControlBlock.hpp"

#include <cstdint>

namespace audioapp {

static constexpr int kGranularMaxGrains = 8;
static constexpr int kGranularMaxClipVoices = 4;

struct GranularFormantControl {
    float blendedHz[3]{};
    float shift = 1.0f;
    float radius = 0.94f;
    float coefficients[3]{};
};

struct GranularFormantFilterState {
    float z1[2][3]{};
    float z2[2][3]{};
};

struct InstrumentModulationContext;

/// Legacy vowel preset positions (formX/formY).
void granularVowelFormPoint(int vowel, float& formX, float& formY) noexcept;

/// RBF blend of 6 vowel formant triples → Hz.
void granularBlendFormants(float formX, float formY, float outHz[3]) noexcept;

/// Cook resonator coeffs for current formant params + sample rate.
void granularCookFormantControl(float formX,
                                float formY,
                                float formantNorm,
                                float character,
                                float sampleRate,
                                GranularFormantControl& out) noexcept;

/// Sum active grains for one note into stereo (or mono if stereoSpread=false).
void granularRenderVoiceGrains(const GranularParams& params,
                               int pitch,
                               float velocity,
                               double elapsedSec,
                               double noteDurationSec,
                               float attackSec,
                               float releaseSec,
                               double sampleRate,
                               bool stereoSpread,
                               float& leftOut,
                               float& rightOut) noexcept;

/// Process one stereo sample through formant resonators.
void granularProcessFormantStereo(float leftIn,
                                  float rightIn,
                                  const GranularFormantControl& ctrl,
                                  GranularFormantFilterState& state,
                                  float& leftOut,
                                  float& rightOut) noexcept;

/// Process one mono sample through formant resonators (bands on channel 0).
float granularProcessFormantMono(float input,
                                 const GranularFormantControl& ctrl,
                                 float z1[3],
                                 float z2[3]) noexcept;

/// Arrangement mix: S&H global auto/LFO every kGranularControlSubBlockFrames.
void mixGranularMidiNotesBlock(float* leftOut,
                               float* rightOut,
                               int numFrames,
                               double sampleRate,
                               int bpm,
                               double playheadStartBeat,
                               const MidiPlaybackNote* notes,
                               int noteCount,
                               const GranularParams& params,
                               GranularFormantFilterState& formantState,
                               const AutomationClipPlayback* automationClips = nullptr,
                               int automationClipCount = 0,
                               const uint16_t* automationDeviceIndex = nullptr,
                               const float* lfoValues = nullptr,
                               int lfoCount = 0,
                               int lfoStride = 0,
                               const ModulationEdgePlayback* modEdges = nullptr,
                               int modEdgeCount = 0,
                               const uint16_t* modulationDeviceIndex = nullptr,
                               const InstrumentModulationContext* instMod = nullptr,
                               const CommonControlBlock* commonControls = nullptr,
                               uint64_t automationTargetNodeId = 0) noexcept;

/// Live / instrument-mode one-voice sample (mono).
float granularLiveVoiceSample(const GranularParams& params,
                              int pitch,
                              float velocity,
                              double elapsedSec,
                              double noteDurationSec,
                              double sampleRate,
                              float z1[3],
                              float z2[3]) noexcept;

} // namespace audioapp
