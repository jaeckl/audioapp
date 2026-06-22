# DeviceChain Refactoring - API and Data Contracts

## Overview

This document defines the exact API and data contracts for the DeviceChain refactoring. All implementation must adhere to these contracts precisely.

## Contract Principles

### Exact Contracts
- Method signatures must match exactly
- Parameter types and order must be preserved
- Return types must be identical
- Threading behavior must be specified

### No Implementation Variance
- Do not invent new behaviors
- Do not change parameter meanings
- Do not modify output expectations
- Do not alter error handling

## Core Data Structures

### DeviceNodePlayback
```cpp
// Owner: DeviceChain.hpp (protected - read-only)
// Used by: All components
struct DeviceNodePlayback {
    DeviceNodeKind kind;
    std::string deviceId;
    bool bypassed;
    float gain;
    float pan;
    int8_t meterSlot;
    DeviceVariantParams params;
};
```

### DeviceVariantParams
```cpp
// Owner: DeviceChain.hpp (protected - read-only)
// Used by: All components
using DeviceVariantParams = std::variant<
    OscillatorParams,
    SamplerParams,
    SubtractiveSynthParams,
    PhaseModSynthParams,
    KickGeneratorParams,
    SnareGeneratorParams,
    ClapGeneratorParams,
    CymbalGeneratorParams,
    CrashGeneratorParams,
    GateParams,
    CompressorParams,
    ExpanderParams,
    LimiterParams,
    TrackGainParams,
    DelayParamsPlayback,
    ReverbParamsPlayback,
    ChorusParamsPlayback,
    PhaserParamsPlayback,
    FilterParams,
    FourBandEqParams,
    FrequencyShifterParams
>;
```

### DeviceMeterAtomic
```cpp
// Owner: DeviceChain.hpp (protected - read-only)
// Used by: Orchestrator only
struct DeviceMeterAtomic {
    std::atomic<float> gainReductionDb{0.0f};
    std::atomic<float> inputPeak{0.0f};
};
```

## Runtime State Structures

### SamplerRuntime
```cpp
// Owner: audioapp/SamplePlayback.hpp (protected - read-only)
// Used by: InstrumentPipeline
struct SamplerRuntime {
    float currentPhase;
    double currentPosition;
    float pitch bendAmount;
    float filterEnvelopeAmount;
};
```

### SubtractiveSynthRuntime
```cpp
// Owner: audioapp/SubtractiveSynth.hpp (protected - read-only)
// Used by: InstrumentPipeline
struct SubtractiveSynthRuntime {
    float noteFrequency;
    float filterEnvAmount;
    float ampEnvAmount;
};
```

### DeviceRuntime Structures (All)
[Each device type has a corresponding Runtime struct that must be maintained]

## API Contracts

### DeviceChainOrchestrator

#### Public API
```cpp
// Owner: DeviceChainOrchestrator.cpp
// Threading: AudioThread only, noexcept
// Error: Returns immediately on nullptr inputs

namespace audioapp {

class DeviceChainOrchestrator {
public:
    // Core processing entry point
    static void processTrackAudio(
        float* trackLeft,
        float* trackRight,
        int numFrames,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceNodePlayback* devices,
        int deviceCount,
        float& oscillatorPhase,
        bool suppressInstruments,
        BiquadState* samplerFilterStates,
        SubtractiveSynthRuntime* subtractiveRuntimes,
        KickGeneratorRuntime* kickRuntimes,
        SnareGeneratorRuntime* snareRuntimes,
        ClapGeneratorRuntime* clapRuntimes,
        CymbalGeneratorRuntime* cymbalRuntimes,
        CrashGeneratorRuntime* crashRuntimes,
        PhaseModSynthRuntime* phaseModRuntimes,
        DynamicsRuntime* dynamicsRuntimes,
        TimeBasedEffectRuntime* timeBasedRuntimes,
        DeviceMeterAtomic* deviceMeters,
        int maxDeviceMeters,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount,
        FilterRuntime* filterRuntimes,
        FourBandEqRuntime* fourBandEqRuntimes,
        FrequencyShifterRuntime* frequencyShifterRuntimes) noexcept;

private:
    // Internal helper - used by other components
    static void computePerFrameGainPan(
        const DeviceNodePlayback& device,
        const AutomationClipPlayback* automationClips,
        int automationClipCount,
        double beat,
        float* outGain,
        float* outPan) noexcept;

    // Internal helper - used by other components  
    static void applyAutomationAtFrame(
        DeviceVariantParams& params,
        DeviceNodeKind kind,
        uint16_t deviceIndex,
        double beat,
        const AutomationClipPlayback* automationClips,
        int automationClipCount) noexcept;

    // Internal helper - used by other components
    static void applyLfoModulationAtFrame(
        DeviceVariantParams& params,
        DeviceNodeKind kind,
        int lfoFrame,
        int framesToProcess,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount) noexcept;
};

} // namespace audioapp
```

#### Contract Details

**processTrackAudio**
- **Purpose**: Main entry point for processing a single audio track
- **Input validation**: Returns immediately if trackLeft/right or devices are nullptr
- **Output**: Modifies trackLeft/trackRight buffers in-place
- **Threading**: AudioThread only, noexcept
- **Parameters**:
  - `trackLeft/right`: Output buffers (must not be nullptr)
  - `numFrames`: Number of frames to process (must be > 0 if buffers valid)
  - `sampleRate`: Audio sample rate (must be > 0)
  - `bpm`: Beats per minute (must be > 0)
  - `playheadStartBeat`: Starting position in beats
  - `notes`: MIDI note events array (can be nullptr)
  - `noteCount`: Size of notes array (0 if notes is nullptr)
  - `devices`: Device chain nodes array (must not be nullptr if deviceCount > 0)
  - `deviceCount`: Size of devices array
  - `oscillatorPhase`: Reference to oscillator phase state (updated in-place)
  - `suppressInstruments`: If true, skip instrument processing
  - **Runtime state pointers**: All must be nullptr or point to valid arrays of sufficient size
  - `maxDeviceMeters`: Size of deviceMeters array
  - `lfoValues`: LFO output data (can be nullptr)
  - `modEdges`: Modulation edges array (can be nullptr)
  - `automationClips`: Timeline automation clips (can be nullptr)
  - `filterRuntimes` etc.: All runtime state arrays (can be nullptr)
- **Return value**: void

**computePerFrameGainPan**
- **Purpose**: Compute gain/pan values for a device at a specific beat
- **Input validation**: Returns immediately if automationClips is nullptr
- **Output**: Modifies outGain and outPan arrays (can be nullptr)
- **Threading**: AudioThread only, noexcept

**applyAutomationAtFrame**
- **Purpose**: Apply timeline automation to device parameters
- **Input validation**: Returns immediately if params invalid
- **Output**: Modifies params in-place
- **Threading**: AudioThread only, noexcept

**applyLfoModulationAtFrame**
- **Purpose**: Apply LFO modulation to device parameters
- **Input validation**: Returns immediately if arrays are nullptr
- **Output**: Modifies params in-place
- **Threading**: AudioThread only, noexcept

#### Dependencies
- `DeviceChainScratchManager::getScratch()` - For scratch space
- `DeviceChainAutomationModulation::applyAutomationAtFrame()` - For automation processing
- `DeviceChainAutomationModulation::applyLfoModulationAtFrame()` - For LFO processing
- `DeviceChainInstrumentPipeline::processDeviceBlock()` - For device processing

### DeviceChainScratchManager

#### Public API
```cpp
// Owner: DeviceChainScratchManager.cpp
// Threading: Thread-local storage only
// Error: None (internal only)

namespace audioapp {

class DeviceChainScratchManager {
public:
    // Get thread-local scratch space
    static DeviceChainScratch& getScratch() noexcept;

private:
    // Internal storage - not directly accessible
    static thread_local DeviceChainScratch gDeviceChainScratch;
};

} // namespace audioapp
```

#### Contract Details

**DeviceChainScratch**
- **Purpose**: Container for all scratch arrays and temporary storage
- **Threading**: Thread-local storage, zero-allocation
- **Contents**:
  - `float scratch[kScratchFrames]`
  - `float tempStereoL[kScratchFrames]`
  - `float tempStereoR[kScratchFrames]`
  - `float perFrameGain[kScratchFrames]`
  - `float perFramePan[kScratchFrames]`
  - `SamplerMidiNoteRegion samplerRegions[kMaxInstrumentRegions]`
  - ... (all other scratch regions)

#### Dependencies
- None (foundational layer)

### DeviceChainAutomationModulation

#### Public API
```cpp
// Owner: DeviceChainAutomationModulation.cpp
// Threading: AudioThread only, noexcept
// Error: Returns immediately on nullptr inputs

namespace audioapp {

class DeviceChainAutomationModulation {
public:
    // Apply timeline automation to device parameters at a specific frame
    static void applyAutomationAtFrame(
        DeviceVariantParams& params,
        DeviceNodeKind kind,
        uint16_t deviceIndex,
        double beat,
        const AutomationClipPlayback* automationClips,
        int automationClipCount) noexcept;

    // Apply LFO modulation to device parameters
    static void applyLfoModulationAtFrame(
        DeviceVariantParams& params,
        DeviceNodeKind kind,
        int lfoFrame,
        int framesToProcess,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount) noexcept;

    // Compute per-frame gain/pan arrays for a device
    static void computePerFrameGainPan(
        const DeviceNodePlayback& device,
        const AutomationClipPlayback* automationClips,
        int automationClipCount,
        double beat,
        float* outGain,
        float* outPan) noexcept;

private:
    // Helper functions for automation evaluation
    static float evaluateAutomationEnvelope(
        const AutomationPointState* points,
        int pointCount,
        float beatInClip) noexcept;

    static void applyAutomationValue(
        DeviceVariantParams& params,
        DeviceNodeKind kind,
        uint16_t localParamId,
        float value) noexcept;
};

} // namespace audioapp
```

#### Contract Details

**applyAutomationAtFrame**
- **Purpose**: Apply timeline automation values from clips to device parameters
- **Input validation**: Returns immediately if params invalid
- **Parameters**:
  - `params`: Device parameters (modified in-place)
  - `kind`: Device type (determines which parameters can be automated)
  - `deviceIndex`: Index of device in chain (for clip matching)
  - `beat`: Current position in beats
  - `automationClips`: Array of automation clips (can be nullptr)
  - `automationClipCount`: Size of automationClips array
- **Threading**: AudioThread only, noexcept

**applyLfoModulationAtFrame**
- **Purpose**: Apply LFO modulation edges to device parameters
- **Input validation**: Returns immediately if any input array is nullptr
- **Parameters**:
  - `params`: Device parameters (modified in-place)
  - `kind`: Device type (determines which parameters respond to LFO)
  - `lfoFrame`: Frame index within LFO processing block
  - `framesToProcess`: Total frames in processing block
  - `lfoValues`: LFO output data (can be nullptr)
  - `lfoCount`: Size of lfoValues array
  - `modEdges`: LFO modulation edges (can be nullptr)
  - `modEdgeCount`: Size of modEdges array
- **Threading**: AudioThread only, noexcept

**computePerFrameGainPan**
- **Purpose**: Compute per-frame gain and pan values including automation
- **Input validation**: Returns immediately if automationClips is nullptr
- **Output**: Modifies outGain and outPan arrays (can be nullptr)
- **Parameters**:
  - `device`: Device node containing base gain/pan
  - `automationClips`: Timeline automation clips
  - `automationClipCount`: Size of automationClips array
  - `beat`: Current beat position
  - `outGain`: Output gain array (can be nullptr)
  - `outPan`: Output pan array (can be nullptr)
- **Threading**: AudioThread only, noexcept

#### Dependencies
- None initially (can be called from orchestrator)
- Uses existing `evaluateAutomationEnvelope` and `applyAutomationValue` from DeviceChain.cpp

### DeviceChainInstrumentPipeline

#### Public API
```cpp
// Owner: DeviceChainInstrumentPipeline.cpp
// Threading: AudioThread only, noexcept
// Error: Returns immediately on nullptr inputs

namespace audioapp {

class DeviceChainInstrumentPipeline {
public:
    // Process instrument devices (oscillator, sampler, synth, generators)
    static void mixInstrumentBlock(
        float* scratch,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceNodePlayback& device,
        const DeviceVariantParams& params,
        const float* perFrameGain,
        const float* perFramePan,
        const SamplerMidiNoteRegion* samplerRegions,
        int samplerRegionCount,
        BiquadState* samplerFilterStates,
        SubtractiveSynthRuntime* subtractiveRuntimes,
        KickGeneratorRuntime* kickRuntimes,
        SnareGeneratorRuntime* snareRuntimes,
        ClapGeneratorRuntime* clapRuntimes,
        CymbalGeneratorRuntime* cymbalRuntimes,
        CrashGeneratorRuntime* crashRuntimes,
        PhaseModSynthRuntime* phaseModRuntimes,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount) noexcept;

    // Process dynamics devices (gate, compressor, expander, limiter)
    static void processDynamicsBlock(
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        const DeviceNodePlayback& device,
        const DeviceVariantParams& params,
        DynamicsRuntime& runtime,
        DeviceMeterAtomic* deviceMeters,
        int deviceMeterSlot) noexcept;

    // Process time-based effect devices
    static void processTimeBasedEffectBlock(
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        const DeviceNodePlayback& device,
        const DeviceVariantParams& params,
        TimeBasedEffectRuntime& runtime) noexcept;

    // Process frequency effect devices
    static void processFrequencyEffectBlock(
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        const DeviceNodePlayback& device,
        const DeviceVariantParams& params,
        FilterRuntime* filterRuntimes,
        FourBandEqRuntime* fourBandEqRuntimes,
        FrequencyShifterRuntime* frequencyShifterRuntimes) noexcept;

private:
    // Device-specific helper functions
    // (Implementation details can be in private implementation file)
};

} // namespace audioapp
```

#### Contract Details

**mixInstrumentBlock**
- **Purpose**: Process instrument devices (oscillators, samplers, synths, generators)
- **Input validation**: Returns immediately if scratch is nullptr
- **Output**: Writes processed audio to scratch buffer
- **Parameters**:
  - `scratch`: Output buffer for processed audio
  - `framesToProcess`: Number of frames to process
  - `sampleRate`: Audio sample rate
  - `bpm`: Beats per minute
  - `playheadStartBeat`: Starting position in beats
  - `notes`: MIDI note events array
  - `noteCount`: Size of notes array
  - `device`: Device node containing parameters
  - `params`: Device parameters
  - `perFrameGain/pan`: Per-frame gain/pan arrays
  - `samplerRegions`: Precomputed MIDI note regions
  - `samplerFilterStates`: Filter state arrays
  - `subtractiveRuntimes` etc.: Device runtime states
  - `lfoValues` etc.: Modulation inputs
- **Threading**: AudioThread only, noexcept

**processDynamicsBlock**
- **Purpose**: Process dynamics effects (gain reduction, compression, expansion, limiting)
- **Input validation**: Returns immediately if track buffers or device are nullptr
- **Output**: Modifies track buffers in-place
- **Threading**: AudioThread only, noexcept

**processTimeBasedEffectBlock**
- **Purpose**: Process time-based effects (delay, reverb, chorus, phaser)
- **Input validation**: Returns immediately if track buffers or device are nullptr
- **Output**: Modifies track buffers in-place
- **Threading**: AudioThread only, noexcept

**processFrequencyEffectBlock**
- **Purpose**: Process frequency effects (filter, EQ, frequency shifter)
- **Input validation**: Returns immediately if track buffers are nullptr
- **Output**: Modifies track buffers in-place
- **Threading**: AudioThread only, noexcept

#### Dependencies
- All existing device mixing functions (from device implementation files)
- `DeviceChainDeviceAdapters` (for wrapper interface)

### DeviceChainDeviceAdapters

#### Public API
```cpp
// Owner: DeviceChainDeviceAdapters.cpp
// Threading: AudioThread only, noexcept
// Error: Returns immediately on nullptr inputs

namespace audioapp {

class DeviceChainDeviceAdapters {
public:
    // Adapter entry points for instrument pipeline
    static void adaptSampler(
        float* scratch,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceNodePlayback& device,
        const SamplerParams& params,
        const float* perFrameGain,
        const float* perFramePan,
        const SamplerMidiNoteRegion* samplerRegions,
        int samplerRegionCount,
        BiquadState* samplerFilterStates,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount) noexcept;

    static void adaptSubtractiveSynth(
        float* scratch,
        int framesToProcess,
        double sampleRate,
        int bpm,
        double playheadStartBeat,
        const MidiPlaybackNote* notes,
        int noteCount,
        const DeviceNodePlayback& device,
        const SubtractiveSynthParams& params,
        const float* perFrameGain,
        const float* perFramePan,
        const SubtractiveMidiNoteRegion* subtractiveRegions,
        int subtractiveRegionCount,
        SubtractiveSynthRuntime& runtime,
        const float* lfoValues,
        int lfoCount,
        const ModulationEdgePlayback* modEdges,
        int modEdgeCount,
        const AutomationClipPlayback* automationClips,
        int automationClipCount) noexcept;

    // Similar adapters for all other device types...
    static void adaptOscillator(float* scratch, int framesToProcess, double sampleRate, float freq);
    static void adaptKickGenerator(float* scratch, int framesToProcess, double sampleRate, const KickGeneratorParams& params);
    static void adaptSnareGenerator(float* scratch, int framesToProcess, double sampleRate, const SnareGeneratorParams& params);
    // ... etc.

    static void adaptDynamics(
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        const DeviceNodePlayback& device,
        const DynamicsParams& params,
        DynamicsRuntime& runtime,
        DeviceMeterAtomic* deviceMeters,
        int deviceMeterSlot) noexcept;

    static void adaptTimeBasedEffect(
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        const DeviceNodePlayback& device,
        const TimeEffectParams& params,
        TimeBasedEffectRuntime& runtime) noexcept;

    static void adaptFrequencyEffect(
        float* trackLeft,
        float* trackRight,
        int framesToProcess,
        double sampleRate,
        const DeviceNodePlayback& device,
        const FrequencyEffectParams& params,
        FilterRuntime* filterRuntimes,
        FourBandEqRuntime* fourBandEqRuntimes,
        FrequencyShifterRuntime* frequencyShifterRuntimes) noexcept;
};

} // namespace audioapp
```

#### Contract Details

Each adapter:
- **Purpose**: Wrapper that adapts new pipeline interface to existing device implementations
- **Input validation**: Returns immediately on nullptr inputs
- **Output**: Writes processed audio to appropriate buffers
- **Threading**: AudioThread only, noexcept
- **Interface**: Matches DeviceChainInstrumentPipeline method signatures
- **Behavior**: Must produce identical output to original device implementation

#### Dependencies
- All existing device implementation files (called by adapters)
- Original DeviceChain.cpp (for reference behavior)

## Interface Compatibility Rules

### Adapter Requirements
1. **Exact Signature Matching**: Adapter method signatures must match pipeline interface exactly
2. **Behavioral Compatibility**: Adapter output must match original device behavior
3. **Parameter Mapping**: Parameters must be mapped correctly between interfaces
4. **Return Value Compatibility**: No return values in original, adapters must not introduce new ones
5. **Error Handling**: Same null pointer handling as original implementations

### Pipeline Interface Requirements
1. **Contract Preservation**: All pipeline contracts must be preserved
2. **Data Flow**: Data must flow correctly from orchestrator to adapters
3. **Parameter Types**: Parameter types must match original device parameters
4. **Output Compatibility**: Output buffers must be written correctly
5. **Thread Safety**: All threading guarantees must be maintained

## Integration Testing Contracts

### Behavioral Compatibility
- **Audio Output**: Frame-by-frame comparison with original DeviceChain.cpp
- **Parameter Processing**: All parameter types must be processed correctly
- **Edge Cases**: Empty arrays, null pointers, boundary conditions
- **Performance**: Processing time within 5% of original
- **Memory**: Zero allocations on AudioThread

### API Contract Testing
- **Method Signatures**: All method signatures must match exactly
- **Parameter Order**: Parameter order must be preserved
- **Type Compatibility**: All types must be compatible
- **Return Values**: No new return values introduced
- **Error Behavior**: Same error handling as original

## Contract Evolution Guidelines

### Breaking Changes
- Only during major version releases
- Must maintain backward compatibility
- Must have comprehensive testing
- Must have migration strategy

### Extension Points
- New device types can be added via adapters
- New processing can be added via pipeline extensions
- New automation can be added via automation modules
- New scratch needs can be added via scratch management

## Quality Gates

### Contract Compliance
- [ ] All method signatures match exactly
- [ ] All parameter types match exactly
- [ ] All return types match exactly
- [ ] Threading contracts preserved
- [ ] Error handling contracts preserved
- [ ] Zero-allocation guarantees maintained
- [ ] Performance targets met
- [ ] All dependencies declared
- [ ] Integration points defined
- [ ] Test coverage complete

This API and data contracts document ensures that all implementation teams work from the same specification, eliminating integration risks and enabling parallel development.