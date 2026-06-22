# Data Contracts: DeviceChainScratchManager

## Purpose
Define all data structures, their layouts, lifetimes, and usage contracts for DeviceChainScratchManager. These contracts specify the exact structure and lifecycle requirements that implementation agents must preserve.

## Contract Principles

### Exact Structure Preservation
- Data structure field layouts must match exactly
- Memory alignment and padding must be preserved
- Array sizes and bounds must be maintained
- Default values and initialization patterns must be identical
- Layout must be identical to existing `DeviceChainScratch` struct

### Lifecycle Management
- Construction and destruction semantics must be specified
- Initialization requirements clearly defined
- Cleanup guarantees must be documented
- Thread safety requirements for shared data
- Memory ownership and lifetime boundaries

### Usage Contracts
- Immutable vs mutable semantics clearly defined
- Producer-consumer relationships specified
- Lifetime boundaries defined
- Access patterns documented
- Thread isolation guarantees

## Core Data Structure Contracts

### DeviceChainScratch Data Contract

**Contract Overview**:
```cpp
// Contract: Complete scratch storage container for AudioThread processing
// Owner: DeviceChainScratchManager (primary implementation)
// Threading: Thread-local storage, zero-allocation
// Lifetime: Per-AudioThread instance, program duration
// Layout: Exactly matches existing DeviceChainScratch from DeviceChain.cpp
```

**Required Structure Layout**:
```cpp
struct DeviceChainScratch {
    // ============================================================================
    // Audio Buffer Arrays - Primary processing buffers
    // ============================================================================
    float scratch[4096];                      // Main scratch buffer
    float tempStereoL[4096];                  // Temporary left stereo buffer
    float tempStereoR[4096];                  // Temporary right stereo buffer
    
    // ============================================================================
    // Per-Frame Control Arrays - Automation and LFO application
    // ============================================================================
    float perFrameGain[4096];                 // Per-frame gain controls
    float perFramePan[4096];                  // Per-frame pan controls
    
    // ============================================================================
    // Instrument Note Region Arrays - MIDI note storage
    // ============================================================================
    SamplerMidiNoteRegion samplerRegions[32];      // Sampler note regions
    SubtractiveMidiNoteRegion subtractiveRegions[32]; // Subtractive synth regions
    KickMidiNoteRegion kickRegions[32];           // Kick generator regions
    SnareMidiNoteRegion snareRegions[32];         // Snare generator regions
    ClapMidiNoteRegion clapRegions[32];           // Clap generator regions
    CymbalMidiNoteRegion cymbalRegions[32];       // Cymbal generator regions
    CrashMidiNoteRegion crashRegions[32];        // Crash generator regions
    PhaseModSynthMidiNoteRegion phaseModRegions[32]; // Phase mod synth regions
    
    // ============================================================================
    // Audio Effect State Arrays - Running DSP filters
    // ============================================================================
    BiquadState samplerNoteFilterStates[32];    // Sampler filter states
};
```

**Structure Requirements**:

| Field | Type | Size | Alignment | Notes |
|-------|------|------|-----------|-------|
| `scratch` | `float[4096]` | 16,384 bytes | Natural | Primary audio processing buffer |
| `tempStereoL` | `float[4096]` | 16,384 bytes | Natural | Left stereo processing buffer |
| `tempStereoR` | `float[4096]` | 16,384 bytes | Natural | Right stereo processing buffer |
| `perFrameGain` | `float[4096]` | 16,384 bytes | Natural | Per-sample gain controls |
| `perFramePan` | `float[4096]` | 16,384 bytes | Natural | Per-sample pan controls |
| `samplerRegions` | `SamplerMidiNoteRegion[32]` | 1,024 bytes | 4-byte | Sampler note regions |
| `subtractiveRegions` | `SubtractiveMidiNoteRegion[32]` | 1,024 bytes | 4-byte | Subtractive synth regions |
| `kickRegions` | `KickMidiNoteRegion[32]` | 640 bytes | 4-byte | Kick generator regions |
| `snareRegions` | `SnareMidiNoteRegion[32]` | 640 bytes | 4-byte | Snare generator regions |
| `clapRegions` | `ClapMidiNoteRegion[32]` | 640 bytes | 4-byte | Clap generator regions |
| `cymbalRegions` | `CymbalMidiNoteRegion[32]` | 640 bytes | 4-byte | Cymbal generator regions |
| `crashRegions` | `CrashMidiNoteRegion[32]` | 640 bytes | 4-byte | Crash generator regions |
| `phaseModRegions` | `PhaseModSynthMidiNoteRegion[32]` | 1,024 bytes | 4-byte | Phase mod synth regions |
| `samplerNoteFilterStates` | `BiquadState[32]` | 1,024 bytes | 4-byte | Sampler filter states |

**Total Size**: ~68,736 bytes per scratch instance
**Alignment**: 4-byte aligned for optimal SIMD access
**Layout**: Contiguous, no padding between structs

### Record Field Contracts

#### SamplerMidiNoteRegion Contract
```cpp
struct SamplerMidiNoteRegion {
    // Contract: Per-sample playback region for sampler processing
    // Owner: audioapp/SamplePlayback.hpp (protected)
    // Lifecycle: Created per note event, consumed per AudioThread block
    // Threading: AudioThread-only access
    
    int pitch = 60;                          // MIDI pitch (60 = middle C)
    double clipStartBeat = 0.0;             // Start of audio clip in beats
    double clipLengthBeats = 4.0;           // Duration of audio clip
    double noteStartBeat = 0.0;             // When note starts in beats  
    double noteDurationBeats = 1.0;         // How long note lasts
    float velocity = 100.0f;                // MIDI velocity (0-127 scale)
};
```

#### SubtractiveMidiNoteRegion Contract
```cpp
struct SubtractiveMidiNoteRegion {
    // Contract: Per-note runtime state for subtractive synthesis
    // Owner: audioapp/SubtractiveSynth.hpp (protected)
    // Lifecycle: Created per note, survives AudioThread block processing
    // Threading: AudioThread-only access
    
    int pitch = 60;                          // MIDI pitch
    int noteKey = 0;                         // Note key for voice stealing
    double clipStartBeat = 0.0;             // Start of audio clip
    double clipLengthBeats = 4.0;           // Clip duration
    double noteStartBeat = 0.0;             // Note start time
    double noteDurationBeats = 1.0;         // Note duration
    float velocity = 100.0f;                // MIDI velocity
};
```

#### KickMidiNoteRegion Contract
```cpp
struct KickMidiNoteRegion {
    // Contract: Per-note state for kick generator
    // Owner: audioapp/KickGenerator.hpp (protected)
    // Lifecycle: Created per note, AudioThread-only access
    
    int pitch = 60;                          // MIDI pitch
    int noteKey = 0;                         // Voice identifier
    double clipStartBeat = 0.0;             // Clip start
    double clipLengthBeats = 4.0;           // Clip duration
    double noteStartBeat = 0.0;             // Note start
    double noteDurationBeats = 1.0;         // Note duration
    float velocity = 100.0f;                // MIDI velocity
};
```

#### SnareMidiNoteRegion Contract
```cpp
struct SnareMidiNoteRegion {
    // Contract: Per-note state for snare generator
    // Owner: audioapp/SnareGenerator.hpp (protected)  
    // Lifecycle: Created per note, AudioThread-only access
    
    int pitch = 60;                          // MIDI pitch
    int noteKey = 0;                         // Voice identifier
    double clipStartBeat = 0.0;             // Clip start
    double clipLengthBeats = 4.0;           // Clip duration
    double noteStartBeat = 0.0;             // Note start
    double noteDurationBeats = 1.0;         // Note duration
    float velocity = 100.0f;                // MIDI velocity
};
```

#### ClapMidiNoteRegion Contract
```cpp
struct ClapMidiNoteRegion {
    // Contract: Per-note state for clap generator
    // Owner: audioapp/ClapGenerator.hpp (protected)
    // Lifecycle: Created per note, AudioThread-only access
    
    int pitch = 60;                          // MIDI pitch
    int noteKey = 0;                         // Voice identifier
    double clipStartBeat = 0.0;             // Clip start
    double clipLengthBeats = 4.0;           // Clip duration
    double noteStartBeat = 0.0;             // Note start
    double noteDurationBeats = 1.0;         // Note duration
    float velocity = 100.0f;                // MIDI velocity
};
```

#### CymbalMidiNoteRegion Contract
```cpp
struct CymbalMidiNoteRegion {
    // Contract: Per-note state for cymbal generator
    // Owner: audioapp/CymbalGenerator.hpp (protected)
    // Lifecycle: Created per note, AudioThread-only access
    
    int pitch = 60;                          // MIDI pitch
    int noteKey = 0;                         // Voice identifier
    double clipStartBeat = 0.0;             // Clip start
    double clipLengthBeats = 4.0;           // Clip duration
    double noteStartBeat = 0.0;             // Note start
    double noteDurationBeats = 1.0;         // Note duration
    float velocity = 100.0f;                // MIDI velocity
};
```

#### CrashMidiNoteRegion Contract
```cpp
struct CrashMidiNoteRegion {
    // Contract: Per-note state for crash generator
    // Owner: audioapp/CrashGenerator.hpp (protected)
    // Lifecycle: Created per note, AudioThread-only access
    
    int pitch = 60;                          // MIDI pitch
    int noteKey = 0;                         // Voice identifier
    double clipStartBeat = 0.0;             // Clip start
    double clipLengthBeats = 4.0;           // Clip duration
    double noteStartBeat = 0.0;             // Note start
    double noteDurationBeats = 1.0;         // Note duration
    float velocity = 100.0f;                // MIDI velocity
};
```

#### PhaseModSynthMidiNoteRegion Contract
```cpp
struct PhaseModSynthMidiNoteRegion {
    // Contract: Per-note state for phase modulation synth
    // Owner: audioapp/PhaseModSynth.hpp (protected)
    // Lifecycle: Created per note, survives AudioThread processing
    // Threading: AudioThread-only access
    
    int pitch = 60;                          // MIDI pitch
    int noteKey = 0;                         // Voice identifier
    double clipStartBeat = 0.0;             // Clip start
    double clipLengthBeats = 4.0;           // Clip duration
    double noteStartBeat = 0.0;             // Note start
    double noteDurationBeats = 1.0;         // Note duration
    float velocity = 100.0f;                // MIDI velocity
};
```

#### BiquadState Contract
```cpp
struct BiquadState {
    // Contract: State for biquad filter processing
    // Owner: audioapp/SamplerFilter.hpp (protected)
    // Lifecycle: Per-instrument filter state, survives AudioThread blocks
    // Threading: AudioThread-only access
    
    float a0 = 1.0f;                        // Filter coefficient a0
    float a1 = 0.0f;                        // Filter coefficient a1  
    float a2 = 0.0f;                        // Filter coefficient a2
    float b1 = 0.0f;                        // Filter coefficient b1
    float b2 = 0.0f;                        // Filter coefficient b2
    float x1 = 0.0f;                        // Previous input sample 1
    float x2 = 0.0f;                        // Previous input sample 2
    float y1 = 0.0f;                        // Previous output sample 1
    float y2 = 0.0f;                        // Previous output sample 2
};
```

## Type Composition Contracts

### DeviceVariantParams Contract
```cpp
// Contract: Union of all device parameter types
// Owner: DeviceChain.hpp (protected)
// Lifecycle: Created by control thread, consumed by AudioThread
// Threading: Read-only on AudioThread

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

**Union Contract Requirements**:
- Type must match `DeviceNodePlayback.kind` field
- Default initialization provided for each type
- Value ranges validated by control thread
- AudioThread must not modify parameter values directly
- Memory layout must support efficient type switching

### Runtime State Contracts

#### DynamicsRuntime Contract
```cpp
struct DynamicsRuntime {
    // Contract: Runtime state for dynamics processors (Gate, Compressor, Expander, Limiter)
    // Owner: engine_juce/include/audioapp (protected)
    // Lifecycle: Per-device runtime, survives AudioThread blocks
    // Threading: AudioThread-only access
    
    float gainReductionDb = 0.0f;           // Current gain reduction in dB
    // Additional runtime state can be added as needed
};
```

#### SubtractiveSynthRuntime Contract
```cpp
struct SubtractiveSynthRuntime {
    // Contract: Voice runtime state for subtractive synthesis
    // Owner: engine_juce/include/audioapp (protected)
    // Lifecycle: Per-voice state, survives AudioThread blocks
    // Threading: AudioThread-only access
    
    // Voice state arrays (implementation-defined size)
    // Contains oscillator states, envelope generators, etc.
};
```

## Lifetime Management Contracts

### Construction Contracts

#### Default Initialization
All scratch structure fields are zero-initialized:
- **Float arrays**: All elements initialized to `0.0f`
- **Struct arrays**: Each element default-initialized
- **Pointers**: Not present in scratch structures

#### Per-Thread Initialization
```cpp
// Contract: Thread-local scratch initialization
void DeviceChainScratchManager::initializeScratch() noexcept {
    // Called at AudioThread startup
    // All static thread_local instances are zero-initialized by C++ standard
    // No explicit initialization required
}
```

### Destruction Contracts

#### No Cleanup Required
```cpp
// Contract: No explicit destruction needed
// Thread-local storage automatically cleaned up with thread termination
// No memory allocation operations during AudioThread lifetime
```

### Lifetime Boundaries

#### ControlThread vs AudioThread
```cpp
// ControlThread Responsibilities:
// - Create DeviceNodePlayback snapshots
// - Write parameter updates via snapshots
// - Initialize scratch manager (compile-time)
// - No direct scratch access

// AudioThread Responsibilities:
// - Read DeviceNodePlayback snapshots  
// - Write to thread-local scratch space
// - Process audio using scratch buffers
// - No cross-thread dependencies
```

#### Scratch Lifetime
```cpp
// Contract: Scratch instance lifetime matches AudioThread session
// - Created when first AudioThread starts
// - Destroyed when last AudioThread terminates  
// - Same instance reused for same thread across multiple sessions
// - Memory footprint: ~68KB per concurrent AudioThread
```

## Thread Isolation Contracts

### Thread-Local Storage Model
```cpp
// Contract: Per-AudioThread scratch isolation
// Implementation: C++ thread_local storage
// Access Pattern: Direct pointer dereference
// Synchronization: None required

thread_local DeviceChainScratch DeviceChainScratchManager::gDeviceChainScratch;
```

### Isolation Guarantees

#### Data Isolation
- Each AudioThread gets its own scratch instance
- No data sharing between AudioThreads
- No race conditions possible
- No cross-thread interference

#### Memory Isolation
- No allocator contention
- No cache line bouncing
- No false sharing between threads
- Optimal memory locality

#### Access Isolation
- Thread-local storage provides automatic isolation
- No explicit locking required
- No atomic operations needed
- Direct pointer access for performance

### Thread Safety Contract

#### Safety Guarantees
```cpp
// Contract: Thread-safe by design, not by implementation
// - Each AudioThread has exclusive access to its scratch space
// - No synchronization overhead for scratch access
// - Impossible to have concurrent access from same thread
// - Impossible to have cross-thread access to same scratch
```

#### Access Patterns
```cpp
// Safe Access Pattern
DeviceChainScratch& scratch = DeviceChainScratchManager::getScratch();
float* buffer = scratch.getScratchBuffer();  // AudioThread only

// Unsafe Cross-Thread Access (contract violation)
void unsafeCrossThreadAccess() {
    DeviceChainScratch& scratch = DeviceChainScratchManager::getScratch();
    // If called from different AudioThread, accessing different scratch instance
    // This is actually safe due to thread_local, but violates abstraction
}
```

## Constants and Size Contracts

### Compile-Time Constants

#### Core Buffer Sizes
```cpp
// Contract: All buffer sizes are compile-time constants
constexpr int kScratchFrames = 4096;                    // Primary buffer size
constexpr int kMaxInstrumentRegions = 32;                // Maximum concurrent notes
constexpr int kAutomationSubBlockFrames = 64;            // Automation block size
constexpr int kMaxDevicesPerTrack = 16;                  // Maximum devices per track
constexpr int kMaxDeviceMeters = 128;                   // Maximum meter slots
```

#### Size Requirements
```cpp
// Contract: Size calculations must be exact
// Required total buffer size calculation:
// 5 buffers * 4096 frames * 4 bytes/frame = 81,920 bytes (primary buffers)
// 8 region arrays * 32 regions * region_size bytes = ~61,440 bytes (region arrays)
// 1 filter array * 32 filters * 32 bytes = 1,024 bytes (filter arrays)
// Total: ~144KB per scratch instance
```

#### Memory Layout Contract
```cpp
// Contract: Memory layout must optimize for:
// - SIMD operations (4-byte aligned)
// - Cache locality (related buffers stored together)
// - Vectorization (float arrays)
// - Register allocation (small fixed sizes)
//
// Implementation must match exact layout for binary compatibility
```

## Usage Pattern Contracts

### Producer-Consumer Contracts

#### ControlThread → AudioThread Data Flow
```cpp
// Contract: ControlThread creates snapshots, AudioThread reads scratch
// ControlThread: Creates DeviceNodePlayback structures
// AudioThread: Reads snapshots into scratch via DeviceChainOrchestrator
//
// Data Flow:
// 1. ControlThread: Build DeviceNodePlayback for each device
// 2. ControlThread: Write parameter updates to DeviceVariantParams
// 3. AudioThread: Copy snapshot to scratch via orchestrator
// 4. AudioThread: Process using scratch buffers
// 5. AudioThread: Write results back to output buffers
```

#### AudioThread → ControlThread Data Flow
```cpp
// Contract: AudioThread writes meters, ControlThread reads them
// AudioThread: Update meter arrays (atomic operations)
// ControlThread: Read meter values for UI display
//
// Data Flow:
// 1. AudioThread: Update DeviceMeterAtomic arrays via scratch
// 2. ControlThread: Read meters for visualization
// 3. ControlThread: May adjust parameters based on meter feedback
```

### Buffer Lifecycle Contracts

#### Scratch Buffer Contract
```cpp
// Contract: Scratch buffer lifecycle within AudioThread
// Initialization: Zero at thread startup
// Usage: Read/write during audio processing
// Modification: Continuous during processing
// Cleanup: No explicit cleanup
//
// Exact lifecycle:
// 1. AudioThread start: All scratch zero-initialized
// 2. AudioThread run: Scratch buffers read/written
// 3. AudioThread stop: Scratch preserved for next use
// 4. Thread termination: Scratch automatically destroyed
```

#### Region Array Contract
```cpp
// Contract: Region array lifecycle
// Initialization: Zero at thread startup
// Usage: Filled by DeviceChainOrchestrator during processing
// Modification: Overwritten per note event
// Safety: No bounds checking (caller responsibility)
//
// Exact lifecycle:
// 1. AudioThread start: All region arrays zero-initialized
// 2. MIDI note-on: Corresponding region filled  
// 3. Audio processing: Regions read during note playback
// 4. Note-off: Region may be cleared or overwritten
```

### Error Handling Contracts

#### Null Pointer Contracts
```cpp
// Contract: nullptr inputs are caller's responsibility
// All scratch accessor methods return non-null pointers
// Utility functions accept pointer parameters
// Contract: Caller must validate pointers before use
//
// Example violation (caller error):
// float* left = nullptr;
// float peak = stereoBlockPeak(left, right, frames); // Undefined behavior
```

#### Buffer Overflow Protection
```cpp
// Contract: Bounds checking is caller's responsibility
// All scratch buffers have fixed compile-time sizes
// Utility functions accept explicit frame counts
// Contract: Caller must ensure frameCount <= buffer_size
//
// Example safe usage:
// DeviceChainScratch& scratch = DeviceChainScratchManager::getScratch();
// float* buffer = scratch.getScratchBuffer();
// int frames = std::min(requestedFrames, kScratchFrames);
// safe_processing(buffer, frames);
```

#### Edge Case Contracts
```cpp
// Contract: Edge cases must be handled gracefully
// frameCount <= 0: Return early or use defaults
// nullptr buffers: Caller must avoid (undefined behavior)
// frames > kScratchFrames: Clamp to buffer size
// Negative values: Treat as invalid (caller responsibility)
```

## Implementation Requirements

### Memory Layout Requirements

#### Binary Compatibility
```cpp
// Contract: Exact memory layout match required
// Requirement: sizeof(DeviceChainScratch) must be preserved
// Requirement: Member offsets must be identical
// Requirement: Alignment must be maintained
//
// Implementation must match:
//   struct DeviceChainScratch {
//       float scratch[4096];
//       float tempStereoL[4096];
//       float tempStereoR[4096];
//       float perFrameGain[4096];
//       float perFramePan[4096];
//       // ... other regions ...
//   };
```

### Initialization Requirements

#### Constructor Requirements
```cpp
// Contract: Default initialization provided
// All fields automatically zero-initialized
// No user-provided constructors needed
// Static initialization is sufficient
//
// Implementation must ensure:
// 1. Float arrays start with 0.0f values
// 2. Struct arrays are default-initialized
// 3. No uninitialized memory access
```

### Performance Contracts

#### Access Time Requirements
```cpp
// Contract: Scratch access must be sub-microsecond
// Requirement: Pointer dereference < 100ns
// Requirement: No function call overhead for hot paths
// Requirement: Cache-friendly memory layout
//
// Implementation must ensure:
// 1. Direct memory access
// 2. Optimal cache alignment
// 3. SIMD-friendly data structures
// 4. Zero indirection for hot paths
```

#### Allocation Requirements
```cpp
// Contract: Zero allocations during AudioThread execution
// Requirement: No heap operations in scratch access
// Requirement: Compile-time allocation only
// Requirement: Static initialization lifetime
//
// Implementation must ensure:
// 1. No 'new'/'delete' in scratch methods
// 2. No 'malloc'/'free' in scratch access
// 3. No dynamic memory during AudioThread
// 4. No runtime memory management
```

## Testing Requirements

### Memory Layout Testing
```cpp
// Contract: Must verify exact memory layout
// Test: sizeof(DeviceChainScratch) == expected_size
// Test: Offset of each member == expected_offset
// Test: Alignment of each member == expected_alignment
//
// Implementation must include layout verification tests
```

### Lifetime Testing
```cpp
// Contract: Must verify lifetime guarantees
// Test: Thread-local storage isolation
// Test: No memory leaks across AudioThread lifecycle
// Test: Proper cleanup on thread termination
//
// Implementation must include lifetime validation tests
```

### Performance Testing
```cpp
// Contract: Must verify performance requirements
// Test: Scratch access timing benchmarks
// Test: Memory allocation verification
// Test: Cache locality measurements
//
// Implementation must include performance regression tests
```

## Conclusion

**Data Contract Summary**:
DeviceChainScratchManager data contracts specify exact structures, layouts, lifetimes, and usage patterns. These contracts ensure binary compatibility, thread safety, and performance guarantees for the scratch management system.

**Key Contract Elements**:
1. **Exact Structures**: All data types defined with precise layouts
2. **Lifetime Management**: Clear ownership and lifetime boundaries
3. **Thread Isolation**: Per-AudioThread storage guarantees
4. **Memory Optimization**: SIMD-friendly, cache-efficient layouts
5. **Error Contracts**: Caller responsibility clearly defined

**Implementation Requirements**:
- Preserve exact binary layout for compatibility
- Implement thread-local storage guarantees
- Maintain zero-allocation performance
- Provide exact memory initialization
- Validate all contracts with comprehensive tests

**Ready for Implementation**:
These data contracts are complete and provide the foundation for DeviceChainScratchManager implementation. All structural requirements, lifecycle guarantees, and usage patterns are clearly defined.