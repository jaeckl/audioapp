# Feature Brief: DeviceChainScratchManager

## Overview
Implement thread-local scratch space management for the AudioThread with zero allocations. This refactoring replaces the monolithic DeviceChain.cpp scratch usage with a dedicated, optimized scratch management system that provides thread-safe, allocation-free temporary storage for audio processing.

## User-Visible Goal
- Zero memory allocations during audio processing on the AudioThread
- Per-thread scratch isolation preventing race conditions
- Maintains full backward compatibility with existing audio processing pipeline
- Enables parallel AudioThread execution

## Non-Goals
- Modifying audio processing algorithms or effects
- Changing any public APIs that expose to Flutter/UI layer
- Adding heap allocations to any AudioThread code
- Redesigning existing device processing logic

## Existing Codebase Analysis

### Current Implementation in DeviceChain.cpp
The existing scratch system uses:
```cpp
thread_local DeviceChainScratch gScratch;
```

Where `DeviceChainScratch` contains:
- `float scratch[kScratchFrames]` (4096)
- `float tempStereoL[kScratchFrames]`, `float tempStereoR[kScratchFrames]`
- `float perFrameGain[kScratchFrames]`, `float perFramePan[kScratchFrames]`
- 8 instrument note region arrays (32 regions each)
- `BiquadState samplerNoteFilterStates[kMaxInstrumentRegions]`

### Key Functions Using Scratch
1. **stereoBlockPeak** - Audio level detection
2. **publishDynamicsMeters** - Meter state updates
3. **isMidiNoteActive** - MIDI note timing validation
4. **applyModulation** - Parameter modulation (multiple overloads)
5. **Utility functions** - Processing coordination

### AudioThread Safety Patterns
- All scratch usage is within AudioThread context
- No exception handling in AudioThread code
- Atomic operations used for shared state
- Thread-local storage ensures isolation

### DeviceNodePlayback and Runtime Types
- `DeviceNodePlayback`: Immutable snapshot per device
- `DynamicsRuntime`: Per-device DSP state
- Various instrument runtime types (SubtractiveSynthRuntime, etc.)

## Architecture Requirements

### Thread-Local Storage Management
- Per-CPU core scratch isolation using `thread_local`
- No allocation or deallocation during audio processing
- Compile-time fixed buffer sizes
- Direct pointer access for performance

### Zero-Allocation Pattern
- All scratch buffers pre-allocated at program start
- No `new`/`delete` or `malloc` in AudioThread path
- Static initialization, lifetime matching program
- Memory ordering guarantees for visibility

### Thread Isolation Utilities
- Thread ID validation and logging utilities
- Cross-thread debugging aids
- Scratch buffer integrity checkers

### Audio Processing Utilities
- Stereo block peak calculation
- Per-frame gain/pan application
- Region management for instrument processing
- Buffer clearing and initialization

## File Structure

### Implementation Files
1. **engine_juce/include/audioapp/DeviceChainScratchManager.hpp**
   - Public interface and data structures
   - Accessor methods for all scratch regions
   - Utility function declarations

2. **engine_juce/src/DeviceChainScratchManager.cpp**
   - Thread-local storage implementation
   - Utility function definitions
   - Zero-allocation access patterns

### Verification Files
3. **engine_juce/tests/DeviceChainScratchManagerTest.hpp**
   - Unit test framework interface

4. **engine_juce/tests/DeviceChainScratchManagerTest.cpp**
   - Thread safety tests
   - Memory allocation verification
   - Performance benchmarks

## Technical Details

### Memory Layout
```cpp
struct DeviceChainScratch {
    float scratch[4096];                      // Main processing buffer
    float tempStereoL[4096];                  // Stereo processing left
    float tempStereoR[4096];                  // Stereo processing right
    float perFrameGain[4096];                 // Per-frame gain controls
    float perFramePan[4096];                  // Per-frame pan controls
    SamplerMidiNoteRegion samplerRegions[32];  // Sampler note regions
    SubtractiveMidiNoteRegion subtractiveRegions[32];  // Subtractive synth regions
    KickMidiNoteRegion kickRegions[32];       // Kick generator regions
    SnareMidiNoteRegion snareRegions[32];     // Snare generator regions
    ClapMidiNoteRegion clapRegions[32];       // Clap generator regions
    CymbalMidiNoteRegion cymbalRegions[32];   // Cymbal generator regions
    CrashMidiNoteRegion crashRegions[32];    // Crash generator regions
    PhaseModSynthMidiNoteRegion phaseModRegions[32];  // Phase mod regions
    BiquadState samplerNoteFilterStates[32];  // Sampler filter states
};
```

### Thread-Local Access Pattern
```cpp
thread_local DeviceChainScratch gDeviceChainScratch;

inline DeviceChainScratch& DeviceChainScratchManager::getScratch() noexcept {
    return gDeviceChainScratch;
}
```

### Zero-Allocation Guarantee
- All methods are `noexcept`
- No heap operations
- Stack local only
- Direct struct member access

## API Specifications

### Core Accessors
```cpp
// Primary scratch buffer
float* getScratchBuffer() noexcept;
const float* getScratchBuffer() const noexcept;

// Stereo processing buffers  
float* getTempStereoL() noexcept;
float* getTempStereoR() noexcept;

// Per-frame control arrays
float* getPerFrameGain() noexcept;
float* getPerFramePan() noexcept;

// Instrument note region arrays
SamplerMidiNoteRegion* getSamplerRegions() noexcept;
SubtractiveMidiNoteRegion* getSubtractiveRegions() noexcept;
KickMidiNoteRegion* getKickRegions() noexcept;
SnareMidiNoteRegion* getSnareRegions() noexcept;
ClapMidiNoteRegion* getClapRegions() noexcept;
CymbalMidiNoteRegion* getCymbalRegions() noexcept;
CrashMidiNoteRegion* getCrashRegions() noexcept;
PhaseModSynthMidiNoteRegion* getPhaseModRegions() noexcept;
BiquadState* getSamplerFilterStates() noexcept;
```

### Utility Functions
```cpp
void clearScratch(int frames) noexcept;
float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept;
DeviceChainScratch& getScratch() noexcept;
```

### Thread Safety Contract
- All access is thread-local (per-AudioThread isolation)
- No locking required for scratch access
- Methods are `noexcept` for hard real-time guarantees
- Memory visibility via thread-local initialization

## Integration Requirements

### Dependencies
- **Provided To**: DeviceChainOrchestrator, DeviceChainAutomationModulation, DeviceChainInstrumentPipeline
- **Dependencies**: None (foundational layer)
- **Conflict Resolution**: None required

### Integration Points
1. **DeviceChainOrchestrator** - Primary scratch consumer
2. **DeviceChainAutomationModulation** - Per-frame gain/pan computation
3. **DeviceChainInstrumentPipeline** - Instrument processing buffers
4. **All Device Types** - Note region access and filter states

### Performance Requirements
- Sub-microsecond scratch access
- Zero function call overhead for hot paths
- Cache-friendly memory layout
- SIMD-friendly vector operations

## Acceptance Criteria

### Functional Requirements
- [ ] Thread-local scratch storage works correctly
- [ ] Zero memory allocations verified under profiling
- [ ] All original scratch-dependent functions operate correctly
- [ ] No race conditions in multi-threaded AudioThread scenarios
- [ ] Scratch buffer integrity maintained across processing blocks

### Non-Functional Requirements
- [ ] Thread safety under 50 concurrent AudioThreads
- [ ] Scratch buffer sizes sufficient for all device types
- [ ] Performance matches or exceeds original implementation
- [ ] No memory leaks or buffer overflows
- [ ] Integration with existing refactoring contracts complete

### Test Requirements
- [ ] Thread safety with concurrent AudioThreads
- [ ] Memory allocation verification
- [ ] Performance benchmarks
- [ ] Buffer overflow detection
- [ ] Scratch space integrity validation
- [ ] Integration verification with orchestrator

## Manual Verification Steps

1. **Multi-Thread Rendering**: Render complex sequences with 50 concurrent AudioThreads
2. **Memory Validation**: Run with dynamic analysis tools (AddressSanitizer, Valgrind)
3. **Performance Measurement**: Compare benchmark metrics with original
4. **Buffer Integrity**: Fuzz testing for buffer overflow/underflow conditions
5. **Cross-Thread Verification**: Validate thread isolation with custom monitoring

## Integration Risk Analysis

### Risk Assessment
- **Severity**: Medium (shared resource foundation)
- **Impact**: High (all packages depend on scratch manager)
- **Probability**: Low (well-established pattern in codebase)

### Mitigation Strategy
- Comprehensive thread safety testing
- Memory allocation verification
- Performance regression testing
- Integration testing with all consumer packages

## Implementation Order

### Recommended Sequence
1. **WP-02: Scratch Space Management** (FOUNDATION) - Parallel-safe
2. **WP-01: DeviceChain Orchestrator** - Sequential (depends on WP-02)
3. **WP-03: Automation and LFO Processing** - Parallel (depends on WP-02)
4. **WP-04: Instrument Pipeline** - Sequential (depends on WP-02 + WP-01)
5. **WP-05: Device Adapters** - Parallel (depends on WP-04)
6. **WP-06: Integration & Testing** - Sequential (all above)

### Package Classification
- **WP-02**: Parallel-safe (no dependencies, foundational)
- **WP-03**: Parallel-safe after WP-02
- **WP-01**: Sequential (depends on WP-02)
- **WP-04**: Sequential (depends on WP-02 + WP-01)
- **WP-05**: Parallel-safe after WP-04
- **WP-06**: Integration-only

## Shared Files Care

### Critical Integration Files
- `DeviceChainOrchestrator.hpp` - Consumer integration
- `DeviceChainAutomationModulation.hpp` - Consumer integration
- `DeviceChainInstrumentPipeline.hpp` - Consumer integration

### File Ownership Conflicts
- Scratch manager owns its implementation files
- Consumers respect scratch manager's access boundaries
- No cross-package file modifications

## Contract Gaps and Risks

### Known Gaps
1. **Missing DeviceChainScratch.hpp**: Currently not implemented per file ownership
2. **Thread Sanitizer Integration**: Need explicit testing configuration
3. **Performance Baseline**: Need original implementation benchmarks for comparison

### Implementation Risks
1. **Thread-Local Initialization**: Global static initialization order
2. **Memory Layout Compatibility**: Must match existing usage patterns
3. **Integration Edge Cases**: Device-specific scratch usage patterns

## Final Summary

This contract establishes DeviceChainScratchManager as the foundational thread-local scratch management system for the DeviceChain refactoring. It provides zero-allocation, thread-safe temporary storage for AudioThread processing while maintaining full compatibility with existing code. The implementation is parallel-safe and serves as the foundation for all downstream packages in the refactoring hierarchy.