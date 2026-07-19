#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/SamplerFilter.hpp"
#include "audioapp/SamplePlaybackAlgorithm.hpp"
#include "audioapp/SubtractiveSynthAlgorithm.hpp"
#include "audioapp/KickAlgorithm.hpp"
#include "audioapp/SnareAlgorithm.hpp"
#include "audioapp/ClapAlgorithm.hpp"
#include "audioapp/DedicatedPercussionAlgorithm.hpp"
#include "audioapp/CrashAlgorithm.hpp"
#include "audioapp/PhaseModSynthAlgorithm.hpp"
#include "audioapp/WavetableSynthAlgorithm.hpp"
#include "audioapp/instruments/PerNoteModulation.hpp"
#include <cstring>
#include <utility>

namespace audioapp {

constexpr int kScratchFrames = 4096;
constexpr int kAutomationSubBlockFrames = 64;
/// Global automation/LFO hold interval for subtractive synth (sample-and-hold).
constexpr int kSubtractiveControlSubBlockFrames = 32;
/// Global automation/LFO hold interval for wavetable synth (sample-and-hold).
constexpr int kWavetableControlSubBlockFrames = 32;
/// Global automation/LFO hold interval for phase-mod synth (sample-and-hold).
constexpr int kPhaseModControlSubBlockFrames = 32;

/// Dedicated preallocated storage for time-based effect ring buffers.
/// One per track. Allows placement-new of ring buffers without heap allocation.
struct DeviceChainScratchArena {
    static constexpr int kBufferSize = 240001;  // 5 seconds at the 48 kHz engine rate
    static constexpr int kMaxTimeBasedEffects = 6;  // Delay, Reverb, Chorus, Phaser, Stutter, spare

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

    /// Return a previously allocated stereo buffer pair to the arena.
    /// Processors are rebuilt independently from this long-lived scratch
    /// storage, so their leases must not remain marked in use after teardown.
    void release(float* left, float* right) noexcept {
        if (left == nullptr || right == nullptr) return;
        for (int i = 0; i < kMaxTimeBasedEffects; ++i) {
            if (left == storage[i][0] && right == storage[i][1]) {
                inUse[i] = false;
                return;
            }
        }
    }

    void reset() noexcept {
        for (int i = 0; i < kMaxTimeBasedEffects; ++i) inUse[i] = false;
    }
};

/// Saved outer-chain scratch buffers while a nested processChain runs.
struct DeviceChainScratchFrame {
    float tempStereoL[kScratchFrames];
    float tempStereoR[kScratchFrames];
    float perFrameGain[kScratchFrames];
    float perFramePan[kScratchFrames];
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
    PercussionMidiNoteRegion percussionRegions[kMaxInstrumentRegions];
    CrashMidiNoteRegion crashRegions[kMaxInstrumentRegions];
    PhaseModSynthMidiNoteRegion phaseModRegions[kMaxInstrumentRegions];
    WavetableMidiNoteRegion wavetableRegions[kMaxInstrumentRegions];
    BiquadState samplerNoteFilterStates[kMaxInstrumentRegions];
    DeviceChainScratchArena ringBufferArena;
    PerNoteModCache perNoteModCache;

    static constexpr int kMaxScratchNestDepth = 8;
    DeviceChainScratchFrame nestFrames[kMaxScratchNestDepth]{};
    int scratchNestDepth = 0;
};

/// RAII push/pop for nested processChain re-entrancy (audio thread only).
class DeviceChainScratchGuard {
public:
    explicit DeviceChainScratchGuard(DeviceChainScratch& scratch,
                                     int numFrames = kScratchFrames) noexcept;
    ~DeviceChainScratchGuard() noexcept;

    DeviceChainScratchGuard(const DeviceChainScratchGuard&) = delete;
    DeviceChainScratchGuard& operator=(const DeviceChainScratchGuard&) = delete;

private:
    DeviceChainScratch& scratch_;
    int savedDepth_ = -1;
    int numFrames_ = 0;
};

} // namespace audioapp
