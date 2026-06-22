# Architecture: DeviceChainScratchManager

## User-Visible Goal
Thread-safe, zero-allocation scratch space management for AudioThread processing. Provides per-thread temporary storage for audio processing operations without runtime heap allocations.

## Non-Goals
- Modifying audio processing algorithms
- Changing existing public APIs
- Adding any form of runtime allocation in AudioThread context
- Redesigning device processing logic or DSP algorithms

## Existing Codebase Analysis

### Current Scratch Implementation
The existing implementation in DeviceChain.cpp uses:

```cpp
thread_local DeviceChainScratch gScratch;
```

**DeviceChainScratch Structure**:
```cpp
struct DeviceChainScratch {
    float scratch[kScratchFrames];                    // Main audio buffer (4096 frames)
    float tempStereoL[kScratchFrames];                // Stereo processing left buffer
    float tempStereoR[kScratchFrames];                // Stereo processing right buffer  
    float perFrameGain[kScratchFrames];               // Per-frame gain controls
    float perFramePan[kScratchFrames];                // Per-frame pan controls
    SamplerMidiNoteRegion samplerRegions[kMaxInstrumentRegions];     // Sampler note regions (32)
    SubtractiveMidiNoteRegion subtractiveRegions[kMaxInstrumentRegions]; // Subtractive synth regions
    KickMidiNoteRegion kickRegions[kMaxInstrumentRegions];          // Kick generator regions
    SnareMidiNoteRegion snareRegions[kMaxInstrumentRegions];         // Snare generator regions
    ClapMidiNoteRegion clapRegions[kMaxInstrumentRegions];           // Clap generator regions
    CymbalMidiNoteRegion cymbalRegions[kMaxInstrumentRegions];       // Cymbal generator regions
    CrashMidiNoteRegion crashRegions[kMaxInstrumentRegions];        // Crash generator regions
    PhaseModSynthMidiNoteRegion phaseModRegions[kMaxInstrumentRegions]; // Phase mod synth regions
    BiquadState samplerNoteFilterStates[kMaxInstrumentRegions];     // Sampler filter states (32)
};
```

### Used By These Functions
From DeviceChain.cpp:
1. **stereoBlockPeak** - Audio level calculation utility
2. **publishDynamicsMeters** - Meter state updates using scratch gain/pan
3. **isMidiNoteActive** - MIDI note timing with region checks
4. **Multiple applyModulation overloads** - Parameter modulation using scratch arrays
5. **Utility functions** - Processing coordination and buffer management

### AudioThread Safety Context
- All scratch usage is confined to AudioThread execution
- No exception handling in AudioThread code path
- Atomic operations used for shared state visibility
- Pattern: Control thread writes snapshots, AudioThread reads/stores to scratch
- Zero exception handling in hot path (real-time safety)

### Key Types Referenced

**DeviceNodePlayback**:
```cpp
struct DeviceNodePlayback {
    DeviceNodeKind kind;              // Device type
    std::string deviceId;             // Unique identifier  
    bool bypassed;                    // Bypass flag
    float gain;                       // Audio gain (0.0-1.0)
    float pan;                        // Stereo pan (0.0-1.0)
    int8_t meterSlot;                 // Meter visualization slot
    DeviceVariantParams params;       // Device-specific parameters (variant)
};
```

**DynamicsRuntime**:
```cpp
struct DynamicsRuntime {
    float gainReductionDb = 0.0f;     // Current gain reduction in dB
    // Additional runtime state for dynamics processors
};
```

**Runtime State Pattern**:
- Multiple device-specific runtime types (SubtractiveSynthRuntime, etc.)
- AudioThread-only state (voice buffers, effect delays, etc.)
- Zero-allocation within AudioThread execution

## Architecture Decision

### Thread-Local Storage Strategy
**Design**: Use C++ `thread_local` storage with compile-time allocated scratch space.

**Rationale**:
- **Zero-allocation guarantee**: Compile-time allocation eliminates runtime heap operations
- **Thread isolation**: Per-thread scratch buffers prevent race conditions  
- **Performance**: Direct pointer access, no synchronization overhead
- **Memory safety**: No allocator contention on AudioThread

**Implementation**:
```cpp
// Single compilation unit implementation
namespace audioapp {
    static thread_local DeviceChainScratch gDeviceChainScratch;
    
    class DeviceChainScratchManager {
    public:
        // Direct accessors to scratch regions
        static float* getScratchBuffer() noexcept { return gDeviceChainScratch.scratch; }
        static float* getTempStereoL() noexcept { return gDeviceChainScratch.tempStereoL; }
        static float* getTempStereoR() noexcept { return gDeviceChainScratch.tempStereoR; }
        // ... other accessors ...
        
        static DeviceChainScratch& getScratch() noexcept { return gDeviceChainScratch; }
    };
}
```

### Zero-Allocation Pattern
**Principles**:
- **Compile-time sizing**: Fixed buffer sizes known at program start
- **Static initialization**: No dynamic allocation during AudioThread processing
- **No exceptions**: All methods `noexcept` for hard real-time guarantees
- **Stack locality**: Conservative memory footprint

**Access Pattern**:
```cpp
// Consumer usage (DeviceChainOrchestrator.cpp)
static void processDeviceChain(...) {
    auto& scratch = DeviceChainScratchManager::getScratch();
    
    // Direct access to scratch regions
    float* scratchBuffer = scratch.getScratchBuffer();
    float* tempL = scratch.getTempStereoL();
    float* tempR = scratch.getTempStereoR();
    float* perFrameGain = scratch.getPerFrameGain();
    
    // Audio processing using scratch buffers
    // ...
}
```

### Module Boundaries

**Package 1: DeviceChainOrchestrator**
- **Owner**: `include/audioapp/DeviceChainOrchestrator.hpp`, `src/DeviceChainOrchestrator.cpp`
- **Responsibility**: Core audio processing coordination
- **Uses**: Scratch space via `DeviceChainScratchManager::getScratch()`

**Package 2: DeviceChainScratchManager** 
- **Owner**: `include/audioapp/DeviceChainScratchManager.hpp`, `src/DeviceChainScratchManager.cpp`
- **Responsibility**: Thread-local scratch space foundation
- **Provides**: Zero-allocation scratch access to all consumers

**Package 3: DeviceChainAutomationModulation**
- **Owner**: `include/audioapp/DeviceChainAutomationModulation.hpp`, `src/DeviceChainAutomationModulation.cpp`
- **Responsibility**: Per-frame gain/pan computation and LFO processing
- **Uses**: Scratch per-frame arrays

**Package 4: DeviceChainInstrumentPipeline**
- **Owner**: `include/audioapp/DeviceChainInstrumentPipeline.hpp`, `src/DeviceChainInstrumentPipeline.cpp`
- **Responsibility**: Device processing pipeline coordination
- **Uses**: Scratch note regions and buffer space

**Package 5: DeviceChainDeviceAdapters**
- **Owner**: `include/audioapp/DeviceChainDeviceAdapters.hpp`, `src/DeviceChainDeviceAdapters.cpp`  
- **Responsibility**: Device type adaptation and interface mapping
- **Uses**: Scratch space via orchestration layer

### Threading Boundaries

**AudioThread Isolation**:
- **Thread Model**: Single producer (control), single consumer (AudioThread) per thread
- **Safety Guarantees**: No cross-thread dependencies in AudioThread
- **Memory Visibility**: Thread-local storage, no atomic operations needed
- **Exception Safety**: All AudioThread code `noexcept`

**ControlThread Responsibilities**:
- Initialize scratch manager (compile-time)
- Create snapshots (DeviceNodePlayback, etc.)
- Coordinate audio thread starts/stops

### Error Model

**Scratch Manager Errors**:
- **Null Inputs**: Input validation on public methods (e.g., `clearScratch`)
- **Boundary Checks**: Frame count validation in buffer operations
- **Thread Safety**: Compile-time enforced via thread_local
- **Recovery**: Return immediately or use safer defaults

**AudioThread Errors**:
- **Assertion Failures**: Compile-time buffer size validation
- **Undefined Behavior**: Prevented via design (zero-allocation, no exceptions)
- **Recovery**: Hard real-time - catastrophic failure recovery

### Persistence Model

**Scratch Lifetime**:
- **Scope**: Per-AudioThread instance
- **Duration**: From program start to termination
- **Initialization**: Static initialization (compile-time)
- **Cleanup**: No explicit cleanup required

**Memory Layout**:
- **Alignment**: Natural alignment for float vectors
- **Padding**: No artificial padding between scratch regions
- **Cache Locality**: Contiguous storage for related operations

### UI/State Synchronization

**Integration Points**:
- **ControlThread → AudioThread**: Parameter updates via snapshots, not scratch
- **AudioThread → ControlThread**: Meter updates via atomic arrays (`DeviceMeterAtomic`)
- **Scratch Access**: Hidden from UI layer (implementation detail)

**Data Flow**:
```
ControlThread               AudioThread
    │                         │
    │ Create Snapshots       │ Read Scratch
    │ (DeviceNodePlayback)   │ (Arrays)
    │                         │
    │ AudioParam Updates     │ Process Audio
    │                       │
    │ Meter Queries         │ Update Meters
    │                       │
    │ ← Meter Results ------ │ 
```

## Data Flow Analysis

### DeviceChainOrchestrator → DeviceChainScratchManager
**Flow**: 
1. AudioThread calls `processTrackAudio`
2. Accesses scratch via `DeviceChainScratchManager::getScratch()`
3. Reads/stores to scratch buffers (instrument processing, effects, etc.)

**Data Dependencies**:
- **Read from Scratch**: Per-frame gain/pan, note regions, filter states
- **Write to Scratch**: Processed audio, per-frame effects, note data
- **Shared Arrays**: Per-instrument runtime states

### DeviceChainAutomationModulation → DeviceChainScratchManager
**Flow**:
1. Compute per-frame gain/pan based on automation curves
2. Store results in scratch `perFrameGain[]` and `perFramePan[]`
3. Read by DeviceChainOrchestrator for audio processing

**Critical Path**: Real-time automation application during audio processing

### DeviceChainInstrumentPipeline → DeviceChainScratchManager
**Flow**:
1. Process MIDI notes into scratch note region arrays
2. Read scratch for instrument-specific processing
3. Write processed audio to scratch buffer
4. Orchestrator reads final scratch buffer for mixdown

**Data Dependencies**:
- **Sampler**: `samplerRegions[]`, filter states
- **SubtractiveSynth**: `subtractiveRegions[]`, runtime state
- **Instrument-specific**: Varies by device type

## Utility Functions

### Core Audio Processing Utilities
```cpp
// Peak detection for audio levels
float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept;

// Per-frame gain/pan application
void applyStereoScalarGain(float* left, float* right, int frames, float gain) noexcept;
void multiplyPerFrameGain(float* buffer, int frames, const float* gain) noexcept;
void mixStereoPerFramePan(float* trackLeft, float* trackRight,
                         const float* mono, int frames,
                         const float* perFramePan) noexcept;
```

### Scratch Management Utilities
```cpp
// Buffer operations
void clearScratch(int frames) noexcept;  // Zero initialize scratch regions
void initializeScratch() noexcept;      // First-time initialization

// Integrity checks
bool validateScratchIntegrity() noexcept; // For debugging
```

### Thread Isolation Utilities
```cpp
// Thread identification and validation
thread_id_t getCurrentThreadId() noexcept;
bool isAudioThread() noexcept;

// Debugging and monitoring
void logScratchUsage() noexcept;
int getScratchUsageStats() noexcept;
```

### Current Function Mapping

**5 Functions from DeviceChain.cpp requiring scratch**:

1. **stereoBlockPeak** → Audio peak utility in DeviceChainScratchManager
2. **publishDynamicsMeters** → Meter publishing remains (scratch unused)
3. **isMidiNoteActive** → MIDI timing validation (scratch unused)
4. **Multiple applyModulation overloads** → Parameter modulation utilities
5. **Utility functions** → Core audio processing helpers

## File Ownership Analysis

### Proposed Files

**DeviceChainScratchManager Files**:
- `engine_juce/include/audioapp/DeviceChainScratchManager.hpp` - Interface
- `engine_juce/src/DeviceChainScratchManager.cpp` - Implementation

**Scratch Definition** (currently missing):
- `engine_juce/include/audioapp/DeviceChainScratch.hpp` - Struct definition

### Existing Code References

**Current Scratch Usage** (in DeviceChain.cpp):
- 42 lines accessing various scratch regions
- Multiple instrument note region arrays
- Filter state arrays
- Audio buffer arrays

**Integration Points**:
- DeviceChainOrchestrator.cpp: Uses scratch managers
- DeviceChainAutomationModulation.cpp: Uses per-frame gain/pan
- Various device implementation files: Use scratch note regions

## Vertical Work Package Context

### WP-02: Scratch Space Management
**User-Visible Behavior**:
- Thread-safe management of per-AudioThread scratch space
- Zero-allocation guarantees for real-time processing
- Foundation for all audio processing components

**Acceptance Criteria**:
- Thread-local storage works correctly
- Zero memory allocations verified under load
- Scratch space sufficient for all device types
- Thread safety validated under concurrent access

**Files**:
- `include/audioapp/DeviceChainScratchManager.hpp`
- `include/audioapp/DeviceChainScratch.hpp` (required but missing)
- `src/DeviceChainScratchManager.cpp`

**Dependencies**:
- **Dependencies**: None (foundational layer)
- **Provided To**: WP-01, WP-03, WP-04, WP-05

**Integration Risk**:
- **Severity**: Medium
- **Impact**: High (all packages depend on it)
- **Mitigation**: Comprehensive thread safety testing

## Implementation Specifications

### Header File Structure
```cpp
#pragma once
#include <atomic>

namespace audioapp {

// Forward declarations of all scratch-using types
struct SamplerMidiNoteRegion;
struct SubtractiveMidiNoteRegion;
// ... other region types ...

class DeviceChainScratchManager {
public:
    // Configuration
    static constexpr int kScratchFrames = 4096;
    static constexpr int kMaxInstrumentRegions = 32;
    
    // Public accessors (all noexcept)
    static float* getScratchBuffer() noexcept;
    static const float* getScratchBuffer() const noexcept;
    static float* getTempStereoL() noexcept;
    static float* getTempStereoR() noexcept;
    static float* getPerFrameGain() noexcept;
    static float* getPerFramePan() noexcept;
    // ... other region accessors ...
    
    // Utility functions
    static void clearScratch(int frames) noexcept;
    static float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept;
    static DeviceChainScratch& getScratch() noexcept;
    
private:
    // Thread-local storage
    static thread_local DeviceChainScratch gDeviceChainScratch;
    
    // Private constructor - static only
    DeviceChainScratchManager() = default;
};

} // namespace audioapp
```

### Implementation File Structure
```cpp
#include "audioapp/DeviceChainScratchManager.hpp"

namespace audioapp {

// Thread-local instance
thread_local DeviceChainScratch DeviceChainScratchManager::gDeviceChainScratch;

// Implementation of accessor methods
float* DeviceChainScratchManager::getScratchBuffer() noexcept {
    return gDeviceChainScratch.scratch;
}

// ... other accessor implementations ...

// Implementation of utility functions
void DeviceChainScratchManager::clearScratch(int frames) noexcept {
    if (frames > 0) {
        std::fill_n(gDeviceChainScratch.scratch, frames, 0.0f);
        std::fill_n(gDeviceChainScratch.tempStereoL, frames, 0.0f);
        std::fill_n(gDeviceChainScratch.tempStereoR, frames, 0.0f);
        std::fill_n(gDeviceChainScratch.perFrameGain, frames, 0.0f);
        std::fill_n(gDeviceChainScratch.perFramePan, frames, 0.0f);
    }
}

// ... other utility implementations ...

} // namespace audioapp
```

### Testing Strategy

**Unit Tests**:
- Thread safety with concurrent AudioThreads
- Memory allocation verification
- Buffer overflow detection
- Scratch space integrity validation

**Integration Tests**:
- Verify all consumer packages work with scratch manager
- Performance benchmarks vs original implementation
- Memory usage validation
- Thread context switching behavior

## Conclusion

**Architecture Summary**:
DeviceChainScratchManager provides a thread-local, zero-allocation scratch space foundation for AudioThread processing. It replaces the monolithic scratch usage in DeviceChain.cpp with a dedicated, optimized management system that ensures thread safety and real-time performance guarantees.

**Key Design Decisions**:
1. **Thread-local storage**: Per-AudioThread isolation without synchronization
2. **Zero-allocation**: Compile-time allocated buffers, no runtime heap operations
3. **Direct access**: Simple pointer-based APIs for performance-critical code
4. **Foundational layer**: No dependencies, provides to all downstream packages

**Integration Impact**:
- Enables parallel AudioThread execution
- Provides foundation for DeviceChain refactoring
- Maintains backward compatibility with existing code
- Supports all device types and audio processing pipelines

**Ready for Implementation**:
- Well-defined module boundaries
- Clear API contracts
- Comprehensive testing strategy
- Defined upgrade path from DeviceChain.cpp