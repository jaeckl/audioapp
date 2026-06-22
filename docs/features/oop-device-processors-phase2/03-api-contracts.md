# OOP Device Processors Phase 2 — API Contracts

This document defines the exact public signatures for every new type. Implementation agents must not deviate from these signatures.

---

## 1. AudioBlock — Stereo Buffer Wrapper

```cpp
// engine_juce/include/audioapp/devices/processors/AudioBlock.hpp
#pragma once

#include <algorithm>
#include <cstring>

namespace audioapp {

struct AudioBlock {
    float* channelL = nullptr;
    float* channelR = nullptr;
    int numSamples = 0;

    AudioBlock() noexcept = default;

    AudioBlock(float* left, float* right, int frames) noexcept
        : channelL(left), channelR(right), numSamples(frames) {}

    /// Zero-fill both channels.
    void clear() noexcept {
        if (channelL) std::memset(channelL, 0, static_cast<size_t>(numSamples) * sizeof(float));
        if (channelR) std::memset(channelR, 0, static_cast<size_t>(numSamples) * sizeof(float));
    }

    /// Accumulate samples from another block (must have same numSamples).
    void addFrom(const AudioBlock& src) noexcept {
        for (int i = 0; i < numSamples && i < src.numSamples; ++i) {
            channelL[i] += src.channelL[i];
            channelR[i] += src.channelR[i];
        }
    }

    /// Multiply both channels by a scalar gain.
    void applyGain(float gain) noexcept {
        for (int i = 0; i < numSamples; ++i) {
            channelL[i] *= gain;
            channelR[i] *= gain;
        }
    }

    /// Multiply both channels by per-frame gain array.
    void applyPerFrameGain(const float* gain) noexcept {
        for (int i = 0; i < numSamples; ++i) {
            channelL[i] *= gain[i];
            channelR[i] *= gain[i];
        }
    }
};

} // namespace audioapp
```

---

## 2. ProcessContext — Consolidated Per-Block Context

```cpp
// engine_juce/include/audioapp/devices/processors/ProcessContext.hpp
#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/LfoTypes.hpp"  // ModulationEdgePlayback

namespace audioapp {

struct ProcessContext {
    /// Thread-local scratch buffers.
    DeviceChainScratch& scratch;

    /// LFO output values: [lfoId * framesToProcess + frame].
    const float* lfoValues = nullptr;
    int lfoCount = 0;

    /// Modulation routing edges (pre-filtered per-track).
    const ModulationEdgePlayback* modEdges = nullptr;
    int modEdgeCount = 0;

    /// Automation clips (pre-filtered per-track).
    const AutomationClipPlayback* automationClips = nullptr;
    int automationClipCount = 0;

    /// Active MIDI notes for this block.
    const MidiPlaybackNote* notes = nullptr;
    int noteCount = 0;

    /// Playhead position in beats.
    double playheadBeat = 0.0;

    /// Tempo in BPM.
    int bpm = 120;

    /// Sample rate in Hz.
    double sampleRate = 48000.0;

    /// If true, instrument processors should skip rendering.
    bool suppressInstruments = false;

    /// Per-device meters array (relaxed atomic stores).
    DeviceMeterAtomic* deviceMeters = nullptr;
    int maxDeviceMeters = 0;

    /// Index of the current device in the chain (set by orchestrator loop).
    int deviceIndex = 0;

    /// Whether the device needs sub-block processing for automation/modulation.
    bool needsSubBlocks = false;

    /// Device parameters (post-automation, post-modulation).
    /// Set by orchestrator before each process() call.
    const DeviceVariantParams* modulatedParams = nullptr;

    ProcessContext(DeviceChainScratch& s) noexcept : scratch(s) {}
};

} // namespace audioapp
```

---

## 3. DeviceProcessor — Abstract Base Class

```cpp
// engine_juce/include/audioapp/devices/processors/DeviceProcessor.hpp
#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/devices/processors/AudioBlock.hpp"
#include "audioapp/devices/processors/ProcessContext.hpp"

namespace audioapp {

class DeviceProcessor {
public:
    /// Initialize internal state from DeviceVariantParams.
    /// Called on the control thread after placement-new construction.
    /// Default does nothing — override if the processor stores internal
    /// state copied from the variant.
    virtual void initParams(const DeviceVariantParams& params) noexcept {
        (void)params;
    }

    /// Process one audio block.
    /// Called on the audio thread. Must be real-time safe.
    virtual void process(AudioBlock& block, ProcessContext& ctx) noexcept = 0;

    /// Return the DeviceNodeKind for introspection/meter routing.
    virtual DeviceNodeKind kind() const noexcept {
        return DeviceNodeKind::Unknown;
    }

    /// Whether the device is bypassed.
    /// Set by the orchestrator from DeviceNodePlayback::bypassed.
    bool bypassed = false;

    /// Slot for meter routing (copied from DeviceNodePlayback::meterSlot).
    int8_t meterSlot = -1;

protected:
    // Prevent direct deletion — arena recycles memory without destructors.
    DeviceProcessor() = default;
    ~DeviceProcessor() = default;
    DeviceProcessor(const DeviceProcessor&) = delete;
    DeviceProcessor& operator=(const DeviceProcessor&) = delete;
};

} // namespace audioapp
```

---

## 4. ProcessorArena — Lock-Free Preallocated Arena

```cpp
// engine_juce/include/audioapp/devices/processors/ProcessorArena.hpp
#pragma once

#include <cstddef>
#include <cstdint>
#include <new>
#include <type_traits>

#include "audioapp/DeviceChain.hpp"  // kMaxDevicesPerTrack
#include "audioapp/devices/processors/DeviceProcessor.hpp"

namespace audioapp {

/// Worst-case processor object size (for arena sizing).
/// Must be >= sizeof(largest concrete processor subclass).
/// Currently estimated — verify with static_assert after all subclasses are defined.
static constexpr size_t kMaxProcessorSize = 256;  // bytes, enough for any processor + runtime
static constexpr size_t kProcessorAlignment = alignof(std::max_align_t);
static constexpr size_t kMaxDeviceStorage = kMaxDevicesPerTrack * kMaxProcessorSize;

class ProcessorArena {
public:
    ProcessorArena() noexcept = default;

    /// Placement-new construct a processor in the arena.
    /// Returns nullptr if the arena is full.
    /// Called on the control thread only.
    template<typename T, typename... Args>
    T* emplace(Args&&... args) noexcept {
        static_assert(sizeof(T) <= kMaxProcessorSize,
                      "Processor subclass exceeds kMaxProcessorSize");
        static_assert(std::is_base_of_v<DeviceProcessor, T>,
                      "T must derive from DeviceProcessor");
        if (size_ >= kMaxDevicesPerTrack) return nullptr;
        void* ptr = storage_ + size_ * kMaxProcessorSize;
        auto* proc = ::new (ptr) T(std::forward<Args>(args)...);
        ++size_;
        return proc;
    }

    /// Read-only access by index. Audio-thread safe after control thread publishes.
    DeviceProcessor* get(int index) const noexcept {
        if (index < 0 || index >= size_) return nullptr;
        return reinterpret_cast<DeviceProcessor*>(
            const_cast<char*>(storage_) + index * kMaxProcessorSize);
    }

    /// Number of processors in the arena.
    int size() const noexcept { return size_; }

    /// Reset without calling destructors.
    /// Memory will be overwritten by next emplace() calls.
    void reset() noexcept { size_ = 0; }

private:
    alignas(kProcessorAlignment) char storage_[kMaxDeviceStorage]{};
    int size_ = 0;
};

/// Static assertion must be placed in a .cpp file once all processor sizes are known:
/// static_assert(sizeof(LargestProcessor) <= kMaxProcessorSize, "...");

} // namespace audioapp
```

---

## 5. DeviceChainOrchestrator — New Orchestrator

```cpp
// engine_juce/include/audioapp/DeviceChainOrchestrator.hpp
#pragma once

#include "audioapp/DeviceChain.hpp"
#include "audioapp/DeviceChainScratch.hpp"
#include "audioapp/AutomationTypes.hpp"
#include "audioapp/devices/processors/DeviceProcessor.hpp"
#include "audioapp/devices/processors/ProcessorArena.hpp"
#include "audioapp/devices/processors/AudioBlock.hpp"
#include "audioapp/devices/processors/ProcessContext.hpp"

namespace audioapp {

struct DeviceChainOrchestrator {

    /// Bridge context — holds everything the orchestrator loop needs.
    /// Populated by the existing processDeviceChain() wrapper.
    struct Context {
        float* trackLeft = nullptr;
        float* trackRight = nullptr;
        int numFrames = 0;
        double sampleRate = 48000.0;
        int bpm = 120;
        double playheadStartBeat = 0.0;
        const MidiPlaybackNote* notes = nullptr;
        int noteCount = 0;
        ProcessorArena& arena;
        DeviceChainScratch& scratch;
        bool suppressInstruments = false;
        DeviceMeterAtomic* deviceMeters = nullptr;
        int maxDeviceMeters = 0;
        const float* lfoValues = nullptr;
        int lfoCount = 0;
        const ModulationEdgePlayback* modEdges = nullptr;
        int modEdgeCount = 0;
        const AutomationClipPlayback* automationClips = nullptr;
        int automationClipCount = 0;

        Context(ProcessorArena& ar, DeviceChainScratch& s) noexcept
            : arena(ar), scratch(s) {}
    };

    /// Main orchestrator loop — replaces the switch-case in processDeviceNode.
    static void processChain(Context& ctx) noexcept;

    /// Apply common gain/pan LFO modulation to per-frame arrays.
    static void applyCommonGainPanLfo(
        DeviceChainScratch& scratch,
        int deviceIndex,
        int framesToProcess,
        const float* lfoValues, int lfoCount,
        const ModulationEdgePlayback* modEdges, int modEdgeCount) noexcept;
};

} // namespace audioapp
```

---

## 6. Processor Factory — Create From DeviceNodePlayback

```cpp
// Function that populates a ProcessorArena from an array of DeviceNodePlayback.
// Lives in DeviceChainOrchestrator.cpp or a standalone factory file.

namespace audioapp {

/// Build processors in the arena from a device chain snapshot.
/// Called on the control thread.
/// Returns the number of processors emplaced.
int buildProcessorChain(
    const DeviceNodePlayback* devices,
    int deviceCount,
    ProcessorArena& arena) noexcept;

} // namespace audioapp
```

---

## 7. Concrete Processor Signatures (All 22)

Each concrete processor changes from:

```cpp
class FilterProcessor {
public:
    static void process(/* 8 params */) noexcept;
};
```

To:

```cpp
class FilterProcessor : public DeviceProcessor {
    FilterRuntime runtime_;  // embedded — no longer passed as pointer
public:
    void initParams(const DeviceVariantParams& params) noexcept override;
    void process(AudioBlock& block, ProcessContext& ctx) noexcept override;
    DeviceNodeKind kind() const noexcept override { return DeviceNodeKind::Filter; }
};
```

All 22 processors follow this exact pattern. The `process()` signature is **identical** across all of them — only internal behavior differs.

### Processor-specific `initParams()` behavior

| Processor | initParams extracts | Internal state member |
|-----------|---------------------|----------------------|
| `TrackGainProcessor` | nothing | none |
| `OscillatorProcessor` | nothing | `float oscillatorPhase_ = 0.0f` |
| `SamplerProcessor` | nothing | `BiquadState samplerFilterStates_[kMaxInstrumentRegions]` |
| `SubtractiveSynthProcessor` | nothing | `SubtractiveSynthRuntime runtime_` |
| `BassSynthProcessor` | nothing | delegates to SubtractiveSynthProcessor |
| `PhaseModSynthProcessor` | nothing | `PhaseModSynthRuntime runtime_` |
| `KickProcessor` | nothing | `KickGeneratorRuntime runtime_` |
| `SnareProcessor` | nothing | `SnareGeneratorRuntime runtime_` |
| `ClapProcessor` | nothing | `ClapGeneratorRuntime runtime_` |
| `CymbalProcessor` | nothing | `CymbalGeneratorRuntime runtime_` |
| `CrashProcessor` | nothing | `CrashGeneratorRuntime runtime_` |
| `GateProcessor` | nothing | `DynamicsRuntime runtime_` |
| `CompressorProcessor` | nothing | `DynamicsRuntime runtime_` |
| `ExpanderProcessor` | nothing | `DynamicsRuntime runtime_` |
| `LimiterProcessor` | nothing | `DynamicsRuntime runtime_` |
| `DelayProcessor` | nothing | `float* bufferL_` / `float* bufferR_` (arena-allocated), `int writeIndex_`, `float lfoPhase_` |
| `ReverbProcessor` | nothing | same as DelayProcessor (uses TimeBasedEffectRuntime layout) |
| `ChorusProcessor` | nothing | same as DelayProcessor |
| `PhaserProcessor` | nothing | same as DelayProcessor + `float phaserStateL_[4]`, `float phaserStateR_[4]` |
| `FilterProcessor` | nothing | `FilterRuntime runtime_` |
| `FourBandEqProcessor` | nothing | `FourBandEqRuntime runtime_` |
| `FrequencyShifterProcessor` | nothing | `FrequencyShifterRuntime runtime_` |

Note: For time-based processors (Delay, Reverb, Chorus, Phaser), the 192K ring buffers are too large for inline members. They are allocated from `DeviceChainScratchArena` during `initParams()`. See data contracts.

### `process()` method behavior per processor family

| Family | Processors | Input | Output | Special |
|--------|-----------|-------|--------|---------|
| Utility | TrackGain | track buffer | track buffer | Multiplies by `scratch.perFrameGain` (legacy, removed in Phase 2 — orchestrator handles this) |
| Instruments | Oscillator, Sampler, SubtractiveSynth, PhaseModSynth, Kick, Snare, Clap, Cymbal, Crash | track buffer (accumulates) | track buffer | Renders into scratch, applies perFrameGain, mixes via perFramePan. `suppressInstruments` skips. |
| Dynamics | Gate, Compressor, Expander, Limiter | track buffer | track buffer | Reads/writes `runtime_`, publishes meters. |
| Time-based | Delay, Reverb, Chorus, Phaser | track buffer | track buffer | Reads/writes ring buffer, publishes meters. |
| Frequency FX | Filter, FourBandEq, FrequencyShifter | track buffer | track buffer | Reads/writes `runtime_`. |

---

## 8. Retained Backward-Compatibility Wrapper

The existing `processDeviceChain()` and `processDeviceNode()` functions in `DeviceChainProcessor.hpp` are **kept** as thin adapters:

```cpp
// In DeviceChainProcessor.cpp (drastically shortened):
namespace audioapp::DeviceChainProcessor {

void processDeviceNode(/* ... old 33 params ... */) noexcept {
    // Deprecated — delegates to DeviceChainOrchestrator::processChain
    // after constructing a temporary arena and ProcessContext.
    // Eventually removed after all callers migrate.
}

} // namespace audioapp::DeviceChainProcessor
```

The old adapter is NOT modified in Phase 2 — it remains as a thin wrapper that converts to the new OOP form internally. This allows incremental migration: the new path is exercised from tests while the old path still works.

---

## 9. DeviceChainScratchArena — Dedicated Arena for Large Ring Buffers

```cpp
// In DeviceChainScratch.hpp (additions):

namespace audioapp {

/// Dedicated preallocated storage for time-based effect ring buffers.
/// One per track. Allows placement-new of ring buffers without heap allocation.
struct DeviceChainScratchArena {
    static constexpr int kBufferSize = 192000;  // 4 seconds at 48 kHz
    static constexpr int kMaxTimeBasedEffects = 4;  // Delay, Reverb, Chorus, Phaser

    /// Raw storage: 2 channels x 192K x 4 possible effects
    float storage[kMaxTimeBasedEffects][2][kBufferSize];

    /// Track which slots are in use (indexed by processor's deviceIndex % kMaxTimeBasedEffects).
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

// Add to DeviceChainScratch:
//   DeviceChainScratchArena ringBufferArena;

} // namespace audioapp
```

---

## Summary of API Changes

| Item | Phase 1 | Phase 2 |
|------|---------|---------|
| Processor class | `class X { static void process(...) noexcept; };` | `class X : DeviceProcessor { void process(AudioBlock&, ProcessContext&) noexcept override; };` |
| Runtime state | External arrays: `FilterRuntime*`, `DynamicsRuntime*`, etc. | Private members: `runtime_`, `oscillatorPhase_`, etc. |
| Large buffers | `new float[192000]` in `TimeBasedEffectRuntime` (heap) | Placement-new from `DeviceChainScratchArena` |
| Dispatcher | 22-way `switch(node.kind)` | Virtual dispatch: `arena.get(i)->process(block, ctx)` |
| Parameters | 33-param function | `ProcessContext& ctx` (1 param) |
| Buffer passing | `float* left, float* right, int frames` | `AudioBlock& block` (1 param) |
| Gain/pan | Each processor does it independently | Orchestrator applies after `process()` |