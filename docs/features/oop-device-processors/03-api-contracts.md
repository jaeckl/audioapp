# OOP Device Processors — API Contracts

This document pins the exact public function declarations, parameter lists, namespace conventions, and header layouts for each of the new processor classes.

## Namespace Design

All processors must reside in the `audioapp` namespace. To keep header inclusion and symbol lookups optimal, do not create unnecessary nested namespaces (use `audioapp::DelayProcessor` rather than `audioapp::devices::processors::DelayProcessor`).

## Function Signature Contract

Each processor will expose a static function `process` with noexcept guarantees. This ensures zero v-table or stack-allocation overhead, and matches the stateless design.

The general function signature format is defined as:

```cpp
namespace audioapp {

class TargetProcessor {
public:
    static void process(
        const DeviceNodePlayback& node,
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceVariantParams& modulatedParams,
        bool needsSubBlocks,
        bool suppressInstruments,
        DeviceChainScratch& scratch,
        float& oscillatorPhase,
        /* Specific runtime parameters */
        DeviceMeterAtomic* deviceMeters,
        int maxDeviceMeters,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount
    ) noexcept;
};

} // namespace audioapp
```

To optimize compiler inlining and prevent stack-frame bloat, each processor can also omit parameters it doesn't utilize, or implement custom parameters. Let's list the specific, tailored interfaces for each family below:

### 1. Utility & Gain
#### `TrackGainProcessor`
```cpp
namespace audioapp {
struct DeviceChainScratch;
struct DeviceNodePlayback;
struct DeviceVariantParams;

class TrackGainProcessor {
public:
    static void process(
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        const DeviceChainScratch& scratch
    ) noexcept;
};
}
```

### 2. Synthesizers & Instruments
#### `OscillatorProcessor`
```cpp
namespace audioapp {
struct DeviceChainScratch;
struct DeviceNodePlayback;
struct MidiPlaybackNote;
struct DeviceVariantParams;
struct ModulationEdgePlayback;
struct AutomationClipPlayback;

class OscillatorProcessor {
public:
    static void process(
        const DeviceNodePlayback& node,
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceVariantParams& modulatedParams,
        bool needsSubBlocks,
        bool suppressInstruments,
        DeviceChainScratch& scratch,
        float& oscillatorPhase,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount
    ) noexcept;
};
}
```

#### `SamplerProcessor`
```cpp
namespace audioapp {
struct DeviceChainScratch;
struct DeviceNodePlayback;
struct MidiPlaybackNote;
struct DeviceVariantParams;
struct ModulationEdgePlayback;
struct AutomationClipPlayback;
struct BiquadState;

class SamplerProcessor {
public:
    static void process(
        const DeviceNodePlayback& node,
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceVariantParams& modulatedParams,
        bool needsSubBlocks,
        bool suppressInstruments,
        DeviceChainScratch& scratch,
        BiquadState* samplerFilterStates,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount
    ) noexcept;
};
}
```

#### `SubtractiveSynthProcessor` & `BassSynthProcessor`
```cpp
namespace audioapp {
struct DeviceChainScratch;
struct DeviceNodePlayback;
struct MidiPlaybackNote;
struct DeviceVariantParams;
struct ModulationEdgePlayback;
struct AutomationClipPlayback;
struct SubtractiveSynthRuntime;

class SubtractiveSynthProcessor {
public:
    static void process(
        const DeviceNodePlayback& node,
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceVariantParams& modulatedParams,
        bool suppressInstruments,
        DeviceChainScratch& scratch,
        SubtractiveSynthRuntime* subtractiveRuntimes,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount
    ) noexcept;
};

class BassSynthProcessor {
public:
    // Reuses the SubtractiveSynthProcessor's internal logic as specified in the original switch block
    static void process(
        const DeviceNodePlayback& node,
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceVariantParams& modulatedParams,
        bool suppressInstruments,
        DeviceChainScratch& scratch,
        SubtractiveSynthRuntime* subtractiveRuntimes,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount
    ) noexcept;
};
}
```

#### `PhaseModSynthProcessor`
```cpp
namespace audioapp {
struct DeviceChainScratch;
struct DeviceNodePlayback;
struct MidiPlaybackNote;
struct DeviceVariantParams;
struct ModulationEdgePlayback;
struct AutomationClipPlayback;
struct PhaseModSynthRuntime;

class PhaseModSynthProcessor {
public:
    static void process(
        const DeviceNodePlayback& node,
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceVariantParams& modulatedParams,
        bool suppressInstruments,
        DeviceChainScratch& scratch,
        PhaseModSynthRuntime* phaseModRuntimes,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount
    ) noexcept;
};
}
```

### 3. Percussion Generators
#### `KickProcessor`
```cpp
namespace audioapp {
struct DeviceChainScratch;
struct MidiPlaybackNote;
struct DeviceVariantParams;
struct KickGeneratorRuntime;

class KickProcessor {
public:
    static void process(
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceVariantParams& modulatedParams,
        bool suppressInstruments,
        DeviceChainScratch& scratch,
        KickGeneratorRuntime* kickRuntimes
    ) noexcept;
};
}
```

#### `SnareProcessor`, `ClapProcessor`, `CymbalProcessor`, `CrashProcessor`
Follow the exact same input/output structure as `KickProcessor`, using their respective runtime state structures:
- `SnareGeneratorRuntime* snareRuntimes`
- `ClapGeneratorRuntime* clapRuntimes`
- `CymbalGeneratorRuntime* cymbalRuntimes`
- `CrashGeneratorRuntime* crashRuntimes`

### 4. Dynamics Processors
#### `GateProcessor`, `CompressorProcessor`, `ExpanderProcessor`, `LimiterProcessor`
```cpp
namespace audioapp {
struct DeviceChainScratch;
struct DeviceNodePlayback;
struct DeviceVariantParams;
struct DynamicsRuntime;
struct DeviceMeterAtomic;

class CompressorProcessor {
public:
    static void process(
        const DeviceNodePlayback& node,
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        const DeviceVariantParams& modulatedParams,
        DeviceChainScratch& scratch,
        DynamicsRuntime* dynamicsRuntimes,
        DeviceMeterAtomic* deviceMeters,
        int maxDeviceMeters
    ) noexcept;
};
}
```
All Dynamics processors (`GateProcessor`, `CompressorProcessor`, `ExpanderProcessor`, `LimiterProcessor`) share this exact signature layout, passing their specific parameter structs (`GateParams`, `CompressorParams`, etc.) extracted from `modulatedParams`.

### 5. Time-Based Effects
#### `DelayProcessor`, `ReverbProcessor`, `ChorusProcessor`, `PhaserProcessor`
```cpp
namespace audioapp {
struct DeviceNodePlayback;
struct DeviceVariantParams;
struct TimeBasedEffectRuntime;
struct DeviceChainScratch;
struct DeviceMeterAtomic;

class DelayProcessor {
public:
    static void process(
        const DeviceNodePlayback& node,
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        DeviceChainScratch& scratch,
        TimeBasedEffectRuntime* timeBasedRuntimes,
        DeviceMeterAtomic* deviceMeters,
        int maxDeviceMeters
    ) noexcept;
};
}
```
Each of these time-based effects uses the shared `TimeBasedEffectRuntime` block array and publishes peak parameters to the meter arrays if available.

### 6. Frequency FX
#### `FilterProcessor`, `FourBandEqProcessor`, `FrequencyShifterProcessor`
```cpp
namespace audioapp {
struct DeviceVariantParams;
struct DeviceChainScratch;

class FilterProcessor {
public:
    static void process(
        int deviceIndex,
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        const DeviceVariantParams& modulatedParams,
        DeviceChainScratch& scratch,
        /* Specific runtime */
        FilterRuntime* filterRuntimes
    ) noexcept;
};
}
```
`FourBandEqProcessor` passes `FourBandEqRuntime*` and `FrequencyShifterProcessor` passes `FrequencyShifterRuntime*`.
All apply `scratch.perFrameGain` multiplication after execution.
