#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/SamplePlayback.hpp"
#include "audioapp/SubtractiveSynth.hpp"
#include "audioapp/KickGenerator.hpp"
#include "audioapp/SnareGenerator.hpp"
#include "audioapp/ClapGenerator.hpp"
#include "audioapp/CymbalGenerator.hpp"
#include "audioapp/CrashGenerator.hpp"
#include "audioapp/PhaseModSynth.hpp"
#include <utility>

namespace audioapp {

constexpr int kScratchFrames = 4096;
constexpr int kAutomationSubBlockFrames = 64;

/// Dedicated preallocated storage for time-based effect ring buffers.
/// One per track. Allows placement-new of ring buffers without heap allocation.
struct DeviceChainScratchArena {
    static constexpr int kBufferSize = 192000;  // 4 seconds at 48 kHz
    static constexpr int kMaxTimeBasedEffects = 4;  // Delay, Reverb, Chorus, Phaser

    /// Raw storage: 2 channels x 192K x 4 possible effects
    float storage[kMaxTimeBasedEffects][2][kBufferSize];

    /// Track which slots are in use.
    bool inUse[kMaxTimeBasedEffects] = {};

    /// Get a pair of left/right buffers for a processor.
    /// Returns {nullptr, nullptr} if no slot available.
    std::pair<float*, float*> allocate() noexcept {
        for (int i = 0; i < kMaxTimeBasedEffects; ++i) {
            if (!inUse[i]) {
                inUse[i] = true;
                return {storage[i][0], storage[i][1]};
            }
        }
        return {nullptr, nullptr};
    }

    void reset() noexcept {
        for (int i = 0; i < kMaxTimeBasedEffects; ++i) inUse[i] = false;
    }
};

struct DeviceChainScratch {
    float scratch[kScratchFrames];
    float tempStereoL[kScratchFrames];
    float tempStereoR[kScratchFrames];
    float perFrameGain[kScratchFrames];
    float perFramePan[kScratchFrames];
    SamplerMidiNoteRegion samplerRegions[kMaxInstrumentRegions];
    SubtractiveMidiNoteRegion subtractiveRegions[kMaxInstrumentRegions];
    KickMidiNoteRegion kickRegions[kMaxInstrumentRegions];
    SnareMidiNoteRegion snareRegions[kMaxInstrumentRegions];
    ClapMidiNoteRegion clapRegions[kMaxInstrumentRegions];
    CymbalMidiNoteRegion cymbalRegions[kMaxInstrumentRegions];
    CrashMidiNoteRegion crashRegions[kMaxInstrumentRegions];
    PhaseModSynthMidiNoteRegion phaseModRegions[kMaxInstrumentRegions];
    BiquadState samplerNoteFilterStates[kMaxInstrumentRegions];
    DeviceChainScratchArena ringBufferArena;
};

} // namespace audioapp