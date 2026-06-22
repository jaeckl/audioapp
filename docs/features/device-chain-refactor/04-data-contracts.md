# DeviceChain Refactoring - Data Contracts

## Overview

This document defines all data contracts for the DeviceChain refactoring. These contracts specify the exact structure, lifecycle, and usage of all data structures used across the new components.

## Data Contract Principles

### Exact Structure Preservation
- Data structures must maintain exact field layouts
- Sizes and alignments must be preserved
- Memory layouts must be identical where referenced
- Default values must match original implementations

### Lifecycle Management
- Construction and destruction semantics must be specified
- Initialization requirements clearly defined
- Cleanup guarantees must be documented
- Thread safety requirements for shared data

### Usage Contracts
- Immutable vs mutable semantics clearly defined
- Producer-consumer relationships specified
- Lifetime boundaries defined
- Access patterns documented

## Core Data Structure Contracts

### DeviceNodePlayback Contract
```cpp
// Contract: Immutable snapshot of device state for AudioThread consumption
// Owner: DeviceChain.hpp (protected)
// Lifecycle: Created by control thread, consumed by AudioThread
// Thread Safety: Read-only on AudioThread, written by control thread

struct DeviceNodePlayback {
    DeviceNodeKind kind;                          // Device type identifier
    std::string deviceId;                         // Unique device identifier
    bool bypassed;                                // Bypass flag
    float gain;                                   // Audio gain (0.0-1.0)
    float pan;                                    // Stereo pan (0.0-1.0)
    int8_t meterSlot;                             // Meter visualization slot
    DeviceVariantParams params;                   // Device-specific parameters
};

Contract Requirements:
- kind: Must be valid DeviceNodeKind value
- deviceId: Non-empty string (if used)
- bypassed: Controls whether device processing is skipped
- gain: Clamped to [0.0, 1.0] in orchestrator
- pan: Clamped to [0.0, 1.0] in orchestrator  
- meterSlot: Valid slot index or -1 (no meter)
- params: Must match kind field (validation in orchestrator)
```

### DeviceVariantParams Contract
```cpp
// Contract: Union of all device parameter types
// Owner: DeviceChain.hpp (protected)
// Lifecycle: Created by control thread, consumed by AudioThread
// Thread Safety: Read-only on AudioThread

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

Contract Requirements:
- Type must match containing DeviceNodePlayback.kind
- Default initialization provided for each type
- Value ranges validated by control thread
- AudioThread must not modify parameter values directly
```

### Runtime State Contracts

#### SamplerRuntime Contract
```cpp
// Contract: Per-sample playback state for AudioThread
// Owner: audioapp/SamplePlayback.hpp (protected)
// Lifecycle: Created per device, survives AudioThread block processing
// Thread Safety: Thread-local, single producer (control), single consumer (audio)

struct SamplerRuntime {
    float currentPhase;                          // Current phase for LFO
    double currentPosition;                      // Current playback position in samples
    float pitchBendAmount;                        // Current pitch bend amount
    float filterEnvelopeAmount;                   // Current filter envelope value
};

Contract Requirements:
- currentPhase: Persists across audio blocks
- currentPosition: Persists across AudioThread blocks
- pitchBendAmount: Updated by control thread, read by AudioThread
- filterEnvelopeAmount: Updated by control thread, read by AudioThread
- Memory layout must match original implementation
```

#### SubtractiveSynthRuntime Contract
```cpp
// Contract: Per-synth runtime state for AudioThread
// Owner: audioapp/SubtractiveSynth.hpp (protected)
// Lifecycle: Created per device, survives AudioThread processing
// Thread Safety: Thread-local

struct SubtractiveSynthRuntime {
    float noteFrequency;                          // Current note frequency
    float filterEnvAmount;                        // Current filter envelope
    float ampEnvAmount;                           // Current amplitude envelope
};

Contract Requirements:
- All fields persist across AudioThread blocks
- Updated only by control thread
- Read-only during AudioThread processing
```

#### DynamicsRuntime Contract
```cpp
// Contract: Shared runtime state for all dynamics devices
// Owner: audioapp/DynamicsProcessor.hpp (protected)
// Lifecycle: Shared across all dynamics devices on same track
// Thread Safety: Array indexing by device index, single AudioThread consumer

struct DynamicsRuntime {
    float detector;                               // Audio level detector
    float envelope;                               // Output envelope
    float gainReduction;                          // Current gain reduction
    float squash;                                 // Nonlinearity amount
    float random;                                 // Noise component
};

Contract Requirements:
- Array-shared: Must be indexed by device index
- Updated by control thread: Set detector, envelope
- Updated by AudioThread: Compute gainReduction
- Read by both threads: Current gainReduction value
```

#### TimeBasedEffectRuntime Contract
```cpp
// Contract: Delay/reverb/chorus/phaser state for AudioThread
// Owner: DeviceChain.hpp (original, protected)
// Lifecycle: Created per time effect device
// Thread Safety: Thread-local, survives AudioThread processing

struct TimeBasedEffectRuntime {
    static constexpr int kBufferSize = 192000;    // 4 seconds at 48kHz
    float* bufferLeft;                            // Left channel delay buffer
    float* bufferRight;                           // Right channel delay buffer
    int writeIndex;                               // Current write position
    float lfoPhase;                               // LFO phase
    float phaserStateL[4];                        // Phaser filter states (left)
    float phaserStateR[4];                        // Phaser filter states (right)
};

Contract Requirements:
- bufferLeft/Right: Allocated by constructor, owned by runtime
- writeIndex: Wraps modulo kBufferSize
- lfoPhase: Persists across AudioThread blocks
- phaserStateL/R: Persist across AudioThread blocks
- Zero-initialized on construction
```

### Meter Storage Contracts

#### DeviceMeterAtomic Contract
```cpp
// Contract: Atomic meter storage for visualization
// Owner: DeviceChain.hpp (protected)
// Lifecycle: Created per track, shared across devices
// Thread Safety: Single producer (AudioThread), multiple consumers (UI)

struct DeviceMeterAtomic {
    std::atomic<float> gainReductionDb;          // Dynamics gain reduction in dB
    std::atomic<float> inputPeak;               // Input peak level
};

Contract Requirements:
- gainReductionDb: Set by AudioThread in dynamics devices
- inputPeak: Set by AudioThread in dynamics devices  
- Atomic operations: Relaxed memory order for performance
- UI consumption: Lock-free reads by control thread
- Values: Float values in dB and linear scale
```

### MIDI and Automation Contracts

#### MidiPlaybackNote Contract
```cpp
// Contract: MIDI note event for instrument processing
// Owner: DeviceChain.hpp (protected)
// Lifecycle: Created by control thread per note event
// Thread Safety: Read-only on AudioThread

struct MidiPlaybackNote {
    int pitch;                                    // MIDI pitch number
    double clipStartBeat;                         // Start time in beats
    double clipLengthBeats;                       // Duration in beats
    double noteStartBeat;                         // Note start within clip
    double noteDurationBeats;                     // Note duration within clip
    float velocity;                               // Note velocity (0-127)
};

Contract Requirements:
- pitch: Valid MIDI pitch (0-127 typical)
- Time values: Calculated by control thread
- velocity: Convert from UI/control input
- Clip values: Used for note mapping within loops
```

#### AutomationClipPlayback Contract
```cpp
// Contract: Timeline automation clip for parameter control
// Owner: audioapp/AutomationTypes.hpp (protected)
// Lifecycle: Created by control thread, consumed by AudioThread
// Thread Safety: Read-only on AudioThread

struct AutomationClipPlayback {
    uint16_t deviceIndex;                         // Device index this clip affects
    uint16_t localParamId;                        // Parameter identifier
    int pointCount;                               // Number of points in clip
    AutomationPointState points[];                // Control points (flexible array)
};

Contract Requirements:
- deviceIndex: Valid device index
- localParamId: Encoded parameter identifier
- pointCount: Number of control points (0 if no points)
- points: Array of control points accessible via index
- Layout: Flexible array member for stack allocation
```

#### ModulationEdgePlayback Contract
```cpp
// Contract: LFO modulation edge for parameter automation
// Owner: audioapp/AutomationTypes.hpp (protected)
// Lifecycle: Created by control thread per modulation edge
// Thread Safety: Read-only on AudioThread

struct ModulationEdgePlayback {
    uint16_t deviceIndex;                         // Device index this edge affects
    uint16_t localParamId;                        // Parameter identifier
    float amount;                                 // Modulation amount multiplier
    uint16_t lfoId;                               // LFO source identifier
};

Contract Requirements:
- deviceIndex: Valid device index
- localParamId: Encoded parameter identifier (excludes gain/pan)
- amount: Modulation multiplier (-1.0 to 1.0 typical)
- lfoId: Index into LFO output array
```

### Scratch Space Contracts

#### DeviceChainScratch Contract
```cpp
// Contract: Thread-local scratch space for AudioThread processing
// Owner: DeviceChainScratch.hpp (new)
// Lifecycle: Created per AudioThread, reused across processing blocks
// Thread Safety: Thread-local storage, single consumer (AudioThread)

struct DeviceChainScratch {
    // Core processing buffers
    float scratch[kScratchFrames];                // General purpose scratch buffer
    float tempStereoL[kScratchFrames];            // Temporary stereo left
    float tempStereoR[kScratchFrames];            // Temporary stereo right
    float perFrameGain[kScratchFrames];           // Per-frame gain values
    float perFramePan[kScratchFrames];            // Per-frame pan values
    
    // Instrument processing regions
    SamplerMidiNoteRegion samplerRegions[kMaxInstrumentRegions];     // Sampler note regions
    SubtractiveMidiNoteRegion subtractiveRegions[kMaxInstrumentRegions]; // Subtractive synth regions
    KickMidiNoteRegion kickRegions[kMaxInstrumentRegions];            // Kick generator regions
    SnareMidiNoteRegion snareRegions[kMaxInstrumentRegions];          // Snare generator regions
    ClapMidiNoteRegion clapRegions[kMaxInstrumentRegions];            // Clap generator regions
    CymbalMidiNoteRegion cymbalRegions[kMaxInstrumentRegions];        // Cymbal generator regions
    CrashMidiNoteRegion crashRegions[kMaxInstrumentRegions];        // Crash generator regions
    PhaseModSynthMidiNoteRegion phaseModRegions[kMaxInstrumentRegions]; // Phase mod synth regions
    BiquadState samplerNoteFilterStates[kMaxInstrumentRegions];     // Sampler note filters
};

Contract Requirements:
- Buffer sizes: Must be sufficiently large for worst-case processing
- Region arrays: Initialized to zero/empty by scratch manager
- Per-frame arrays: Valid for processing duration
- Thread-local: Each AudioThread gets its own instance
- Zero-allocation: All memory allocated at thread creation time
```

## Data Flow Contracts

### Orchestrator → ScratchManager
```cpp
// Data Flow: DeviceChainOrchestrator -> DeviceChainScratchManager

// Contract: Scratch space acquisition and management
// Source: Orchestrator computes required buffer sizes
// Target: ScratchManager provides thread-local storage
// Usage: All components use scratch space via orchestrator

// Orchestrator usage:
DeviceChainScratch& scratch = DeviceChainScratchManager::getScratch();

// ScratchManager guarantees:
- Allocation: Happens once per AudioThread
- Lifetime: Persists until AudioThread termination
- Thread safety: Zero contention between AudioThreads
- Zero-allocation: Pointer stability guaranteed
```

### Orchestrator → AutomationModulation
```cpp
// Data Flow: DeviceChainOrchestrator -> DeviceChainAutomationModulation

// Contract: Per-frame automation and LFO processing
// Source: Orchestrator provides device parameters and frame info
// Target: AutomationModulation computes gain/pan and parameter modulation
// Usage: Orchestrator calls automation functions before device processing

// Automation usage:
DeviceChainAutomationModulation::computePerFrameGainPan(
    device, automationClips, beat, outGain, outPan);

DeviceChainAutomationModulation::applyAutomationAtFrame(
    params, kind, deviceIndex, beat, automationClips);

DeviceChainAutomationModulation::applyLfoModulationAtFrame(
    params, kind, lfoFrame, lfoCount, lfoValues, modEdges);
```

### Orchestrator → InstrumentPipeline
```cpp
// Data Flow: DeviceChainOrchestrator -> DeviceChainInstrumentPipeline

// Contract: Device-specific processing
// Source: Orchestrator provides processed parameters and scratch space
// Target: InstrumentPipeline writes audio to scratch buffer
// Usage: Orchestrator calls pipeline functions for each device

// Pipeline usage:
DeviceChainInstrumentPipeline::mixInstrumentBlock(
    scratch, framesToProcess, sampleRate, bpm, playheadStartBeat,
    notes, noteCount, device, params, perFrameGain, perFramePan,
    samplerRegions, samplerFilterStates, lfoValues, modEdges, automationClips);
```

### InstrumentPipeline → DeviceAdapters
```cpp
// Data Flow: DeviceChainInstrumentPipeline -> DeviceChainDeviceAdapters

// Contract: Device processing adaptation
// Source: Pipeline provides formatted inputs and runtime states
// Target: Adapters call original device implementations
// Usage: Pipeline delegates device-specific processing to adapters

// Adapter usage:
DeviceChainDeviceAdapters::adaptSampler(...);
DeviceChainDeviceAdapters::adaptSubtractiveSynth(...);
// ... etc for all device types
```

### AudioThread → ControlThread
```cpp
// Data Flow: AudioThread -> ControlThread (meter data)

// Contract: Meter data publication
// Source: AudioThread computes meter values in dynamics devices
// Target: ControlThread reads for UI display
// Usage: Atomic meter storage shared between threads

// AudioThread usage:
publishDynamicsMeters(node, runtime, inputPeak, deviceMeters, maxDeviceMeters);

// ControlThread usage:
float gainReduction = deviceMeters[slot].gainReductionDb.load();
float inputPeak = deviceMeters[slot].inputPeak.load();
```

## Memory Management Contracts

### Allocation Contracts
```cpp
// Orchestrator Component:
// - Zero allocations
// - Uses thread-local scratch space only
// - nullptr checks at public API boundaries

// ScratchManager Component:
// - Zero allocations after thread creation
// - Static thread_local storage
// - No dynamic memory management

// Pipeline Component:
// - Zero allocations during AudioThread processing
// - Uses pre-allocated runtime states
// - Runtime states allocated by control thread

// Adapter Component:
// - Zero allocations during AudioThread processing
// - Calls original device implementations (which may allocate in control thread)
// - No new allocations in AudioThread
```

### Lifetime Contracts
```cpp
// Control Thread Lifetime:
// - Game loop scope (process command buffers)
// - Device creation/destruction
// - Parameter updates
// - Runtime state allocation

// Audio Thread Lifetime:
// - Single AudioThread per CPU core
// - Joins at engine shutdown
// - Thread-local data persists until thread exit
// - No cleanup required during normal operation

// Data Lifetime:
// - DeviceNodePlayback: Valid for entire track processing
// - DeviceVariantParams: Valid for device processing block
// - Runtime states: Valid for device lifetime
// - Scratch space: Valid for AudioThread lifetime
```

## Consistency Contracts

### Parameter Consistency
```cpp
// Parameter synchronization:
// - Control thread updates DeviceNodePlayback::params
// - AudioThread reads DeviceNodePlayback::params atomically
// - No intermediate states visible
// - Snapshot semantics: Either all old params or all new params

// Type consistency:
// - DeviceNodePlayback::kind determines DeviceVariantParams variant type
// - Mismatch causes undefined behavior (sanitizable)
// - Control thread maintains consistency
```

### Timing Consistency
```cpp
// Beat consistency:
// - All timing values in beats
// - Beat to frame conversion consistent across components
// - Playhead timing synchronized
// - LFO phase consistent across devices

// Frame consistency:
// - Processing happens in frames
// - Buffer sizes consistent across components
// - Scratch buffer sized for maximum frames
// - Per-frame arrays indexed consistently
```

## Performance Contracts

### Time Complexity
```cpp
// Processing contracts:
// - Per device: O(frames) where frames ≤ kScratchFrames (4096)
// - Per track: O(devices × frames)
// - Per automation: O(clips × points) (control thread)
// - Per LFO: O(edges × frames)

// Memory contracts:
// - Per AudioThread: kScratchFrames × sizeof(float) × 7 = ~768KB
// - Per device: Runtime state size
// - No allocations during AudioThread processing
// - Thread-local to avoid contention
```

### Throughput Requirements
```cpp
// Minimum performance targets:
// - 48kHz sample rate: 4096 samples = 85.33ms processing window
// - Maximum devices: 16 per track
// - Maximum processing time per block: < 1ms
// - CPU utilization: < 10% on modern cores
// - Memory bandwidth: Efficient scratch reuse
```

## Testing Contracts

### Data Structure Validation
```cpp
// Test requirements:
// - Memory layout matching original
// - Initialization completeness
// - Value range validity
// - Thread safety scenarios
// - Integration with other components

// Test scenarios:
// - Null pointer handling
// - Boundary conditions
// - Concurrent access (where applicable)
// - Memory corruption detection
// - Performance validation
```

### Contract Verification
```cpp
// Verification requirements:
// - Static analysis for layout consistency
// - Runtime validation of invariants
// - Integration testing with all components
// - Performance benchmarking
// - Memory leak detection
// - Thread safety verification
```

## Migration Contracts

### Backward Compatibility
```cpp
// Migration requirements:
// - No API changes
// - No behavior changes
// - No performance degradation
// - No memory usage increase
// - No thread safety issues

// Migration strategy:
// - Gradual rollout by component
// - Unit testing before integration
// - Integration testing before production
// - Performance validation before deployment
```

### Extension Contracts
```cpp
// Extension requirements:
// - New device types via adapters
// - New processing modules via pipeline
// - New automation via automation system
// - New scratch needs via scratch manager
// - New metering via meter system

// Extension points:
// - Device adapter registration
// - Pipeline extension hooks
// - Automation system plug-ins
// - Scratch space extension APIs
```

This comprehensive data contracts document ensures that all components implement consistent, correct, and performant data handling across the refactoring. All teams must adhere to these contracts to guarantee integration success.