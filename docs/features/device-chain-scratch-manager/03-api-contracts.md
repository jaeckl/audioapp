# API Contracts: DeviceChainScratchManager

## Purpose
Define exact public APIs, method signatures, and contracts for DeviceChainScratchManager. These contracts specify the precise interface that implementation agents must follow without deviation.

## Contract Principles

### Exact Signature Preservation
- Method signatures must match exactly
- Parameter types, order, and default values must be preserved
- Return types must be exact (no aliases or generics)
- `noexcept` specification must be maintained
- Threading contracts must be explicitly documented

### Owner Responsibilities
- **DeviceChainScratchManager.cpp**: Sole owner of implementation
- **DeviceChainScratchManager.hpp**: Sole owner of interface
- No cross-package API modifications
- Maintain binary compatibility with consumers

### Consumer Requirements
- Call APIs exactly as specified
- Respect threading contracts (AudioThread vs ControlThread)
- Handle nullptr inputs as specified
- Maintain exact error contract behavior

## Public API Specification

### Core Interface
```cpp
namespace audioapp {

class DeviceChainScratchManager {
public:
    // ============================================================================
    // Primary Accessor - Thread-local scratch space
    // ============================================================================
    
    /**
     * Get reference to thread-local scratch space.
     * 
     * Contract: AudioThread-only access, zero-allocation, noexcept
     * Threading: Must be called from AudioThread context
     * Allocations: None (compile-time allocated)
     * Errors: None (internal state invariant)
     * 
     * Returns: Reference to thread-local DeviceChainScratch structure
     */
    static DeviceChainScratch& getScratch() noexcept;
    
    // ============================================================================
    // Primary Buffer Accessors - Direct scratch space access
    // ============================================================================
    
    /**
     * Get pointer to primary scratch buffer (left channel processing).
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None (safety is caller's responsibility)
     * 
     * Returns: Pointer to scratch buffer array (kScratchFrames elements)
     */
    static float* getScratchBuffer() noexcept;
    
    /**
     * Get constant pointer to primary scratch buffer.
     * 
     * Contract: AudioThread-only, const access, noexcept
     * Threading: AudioThread context only  
     * Allocations: None
     * Errors: None
     * 
     * Returns: Constant pointer to scratch buffer array
     */
    static const float* getScratchBuffer() const noexcept;
    
    /**
     * Get pointer to left stereo temporary buffer.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to tempStereoL buffer array (kScratchFrames elements)
     */
    static float* getTempStereoL() noexcept;
    
    /**
     * Get pointer to right stereo temporary buffer.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to tempStereoR buffer array (kScratchFrames elements)
     */
    static float* getTempStereoR() noexcept;
    
    /**
     * Get pointer to per-frame gain array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to perFrameGain array (kScratchFrames elements)
     */
    static float* getPerFrameGain() noexcept;
    
    /**
     * Get pointer to per-frame pan array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to perFramePan array (kScratchFrames elements)
     */
    static float* getPerFramePan() noexcept;
    
    // ============================================================================
    // Note Region Accessors - Instrument note storage
    // ============================================================================
    
    /**
     * Get pointer to sampler note regions array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to samplerRegions array (kMaxInstrumentRegions elements)
     */
    static SamplerMidiNoteRegion* getSamplerRegions() noexcept;
    
    /**
     * Get pointer to subtractive synth note regions array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to subtractiveRegions array (kMaxInstrumentRegions elements)
     */
    static SubtractiveMidiNoteRegion* getSubtractiveRegions() noexcept;
    
    /**
     * Get pointer to kick generator note regions array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to kickRegions array (kMaxInstrumentRegions elements)
     */
    static KickMidiNoteRegion* getKickRegions() noexcept;
    
    /**
     * Get pointer to snare generator note regions array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to snareRegions array (kMaxInstrumentRegions elements)
     */
    static SnareMidiNoteRegion* getSnareRegions() noexcept;
    
    /**
     * Get pointer to clap generator note regions array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to clapRegions array (kMaxInstrumentRegions elements)
     */
    static ClapMidiNoteRegion* getClapRegions() noexcept;
    
    /**
     * Get pointer to cymbal generator note regions array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to cymbalRegions array (kMaxInstrumentRegions elements)
     */
    static CymbalMidiNoteRegion* getCymbalRegions() noexcept;
    
    /**
     * Get pointer to crash generator note regions array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to crashRegions array (kMaxInstrumentRegions elements)
     */
    static CrashMidiNoteRegion* getCrashRegions() noexcept;
    
    /**
     * Get pointer to phase mod synth note regions array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to phaseModRegions array (kMaxInstrumentRegions elements)
     */
    static PhaseModSynthMidiNoteRegion* getPhaseModRegions() noexcept;
    
    /**
     * Get pointer to sampler filter states array.
     * 
     * Contract: AudioThread-only, nobounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None
     * 
     * Returns: Pointer to samplerNoteFilterStates array (kMaxInstrumentRegions elements)
     */
    static BiquadState* getSamplerFilterStates() noexcept;
    
    // ============================================================================
    // Utility Functions - Scratch space management and processing
    // ============================================================================
    
    /**
     * Zero-initialize scratch buffers.
     * 
     * Contract: AudioThread-only, safe bounds checking, noexcept
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None (invalid input handled gracefully)
     * 
     * Parameters:
     *   frames: Number of frames to clear (must be >= 0)
     *   If frames <= 0, function does nothing
     *   If frames > kScratchFrames, only first kScratchFrames frames cleared
     */
    static void clearScratch(int frames) noexcept;
    
    /**
     * Calculate peak value from stereo audio buffers.
     * 
     * Contract: AudioThread-only, noexcept, deterministic
     * Threading: AudioThread context only
     * Allocations: None
     * Errors: None (simple mathematical computation)
     * 
     * Parameters:
     *   left: Pointer to left channel buffer (non-null)
     *   right: Pointer to right channel buffer (non-null)  
     *   frameCount: Number of frames to process (must be >= 0)
     *   Returns: Maximum absolute value found in both channels
     *   If frameCount <= 0, returns 0.0f
     */
    static float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept;
    
private:
    // ============================================================================
    // Internal Storage - Thread-local scratch space
    // ============================================================================
    
    /**
     * Thread-local scratch space instance.
     * 
     * Contract: AudioThread-only access, zero-allocation storage
     * Threading: Each AudioThread gets its own instance
     * Allocations: None (compile-time allocated)
     * Errors: None (static storage)
     */
    static thread_local DeviceChainScratch gDeviceChainScratch;
    
    // Private constructor - static interface only
    DeviceChainScratchManager() = default;
};

} // namespace audioapp
```

## Contract Details

### Method Contracts

#### getScratch()

**Preconditions**:
- Must be called from AudioThread context
- No cross-thread dependencies
- AudioThread hot path safety required

**Postconditions**:
- Returns reference to thread-local scratch storage
- No side effects
- Same instance returned for same thread

**Threading Model**:
- **Producer**: ControlThread (initial allocation)
- **Consumer**: AudioThread (read/write access)
- **Isolation**: Per-thread scratch storage
- **Safety**: No synchronization required

**Allocation Behavior**:
- Zero allocations during AudioThread execution
- Compile-time allocation at program startup
- Static initialization, no dynamic memory

**Error Contract**:
- No runtime errors
- Invalid state is impossible due to design
- All inputs validated implicitly by type system

#### Buffer Accessor Contracts

**Common Contract for All Buffer Accessors**:
- **Threading**: AudioThread only
- **Allocation**: None
- **Bounds Checking**: Caller responsible
- **Error Handling**: None (unsafe API)
- **Use Case**: Performance-critical hot path

**Specific Contracts**:
- All return non-null pointers (thread-local storage always valid)
- Pointers valid for entire AudioThread execution
- No lifetime guarantees across AudioThread boundaries
- SIMD-friendly alignment (natural for float arrays)

#### clearScratch(frames)

**Input Validation**:
```cpp
void clearScratch(int frames) noexcept {
    if (frames <= 0) return;  // Early exit for invalid input
    if (frames > kScratchFrames) {
        frames = kScratchFrames;  // Clamp to buffer size
    }
    std::fill_n(gDeviceChainScratch.scratch, frames, 0.0f);
    // ... zero other buffers similarly ...
}
```

**Error Contract**:
- No exceptions thrown
- Invalid input handled gracefully
- Never leaves scratch in partially initialized state

#### stereoBlockPeak(left, right, frameCount)

**Mathematical Contract**:
```cpp
float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept {
    float peak = 0.0f;
    for (int i = 0; i < frameCount; ++i) {
        peak = std::max(peak, std::max(std::abs(left[i]), std::abs(right[i])));
    }
    return peak;
}
```

**Edge Case Contracts**:
- frameCount <= 0: Returns 0.0f (no-op)
- nullptr inputs: Contract violation (caller responsibility)
- frameCount > buffer size: Processes exactly frameCount samples
- Deterministic output for same inputs
- No floating-point non-determinism

### Data Structure Contracts

#### DeviceChainScratch Structure

```cpp
struct DeviceChainScratch {
    // ============================================================================
    // Primary Processing Buffers - Audio output accumulation
    // ============================================================================
    float scratch[kScratchFrames];                    // Main scratch buffer
    float tempStereoL[kScratchFrames];                // Temporary left stereo buffer  
    float tempStereoR[kScratchFrames];                // Temporary right stereo buffer
    
    // ============================================================================
    // Per-Frame Control Arrays - Automation and LFO application
    // ============================================================================
    float perFrameGain[kScratchFrames];               // Per-frame gain controls
    float perFramePan[kScratchFrames];                // Per-frame pan controls
    
    // ============================================================================
    // Instrument Note Regions - MIDI note storage and processing
    // ============================================================================
    SamplerMidiNoteRegion samplerRegions[kMaxInstrumentRegions];      // Sampler note regions
    SubtractiveMidiNoteRegion subtractiveRegions[kMaxInstrumentRegions]; // Subtractive synth regions
    KickMidiNoteRegion kickRegions[kMaxInstrumentRegions];           // Kick generator regions
    SnareMidiNoteRegion snareRegions[kMaxInstrumentRegions];         // Snare generator regions
    ClapMidiNoteRegion clapRegions[kMaxInstrumentRegions];           // Clap generator regions
    CymbalMidiNoteRegion cymbalRegions[kMaxInstrumentRegions];       // Cymbal generator regions
    CrashMidiNoteRegion crashRegions[kMaxInstrumentRegions];        // Crash generator regions
    PhaseModSynthMidiNoteRegion phaseModRegions[kMaxInstrumentRegions]; // Phase mod synth regions
    
    // ============================================================================
    // Audio Effect State - Running DSP filters and processors
    // ============================================================================
    BiquadState samplerNoteFilterStates[kMaxInstrumentRegions];       // Sampler filter states
};
```

**Layout Contract**:
- **Memory Alignment**: Naturally aligned for float vectors
- **Contiguous Storage**: Related buffers stored together
- **No Padding**: No artificial padding between members
- **Fixed Size**: Exact size at compile-time: kScratchSize bytes

**Lifetime Contract**:
- **Scope**: Per-AudioThread instance
- **Duration**: From program start to termination
- **Initialization**: Static initialization (zero values)
- **Cleanup**: No explicit cleanup required

**Threading Contract**:
- **Access Pattern**: AudioThread read/write, ControlThread read-only
- **Isolation**: Each AudioThread gets its own instance
- **Safety**: No race conditions due to thread-local storage

## Dependencies

### Base Dependencies

**Foundational Components**:
- `DeviceChainScratch.hpp` - Struct definition (created by DeviceChainScratchManager)
- `SamplePlayback.hpp` - SamplerMidiNoteRegion definition
- `SubtractiveSynth.hpp` - SubtractiveMidiNoteRegion definition
- `KickGenerator.hpp` - KickMidiNoteRegion definition
- `SnareGenerator.hpp` - SnareMidiNoteRegion definition
- `ClapGenerator.hpp` - ClapMidiNoteRegion definition
- `CymbalGenerator.hpp` - CymbalMidiNoteRegion definition
- `CrashGenerator.hpp` - CrashMidiNoteRegion definition
- `PhaseModSynth.hpp` - PhaseModSynthMidiNoteRegion definition
- `SamplerFilter.hpp` - BiquadState definition

### Consumer Dependencies

**Required By These Work Packages**:
1. **WP-01: DeviceChainOrchestrator** - Primary scratch consumer
2. **WP-03: DeviceChainAutomationModulation** - Per-frame gain/pan computation
3. **WP-04: DeviceChainInstrumentPipeline** - Instrument processing buffers
4. **WP-05: DeviceChainDeviceAdapters** - Device type adaptation

**Exact API Usage**:
- `DeviceChainScratchManager::getScratch()` - Primary accessor
- All `get*Regions()` methods - Note region access
- `stereoBlockPeak()` - Audio peak calculation
- `clearScratch()` - Buffer initialization

### Dependency Contract

**Integration Points**:
```cpp
// DeviceChainOrchestrator.cpp
auto& scratch = DeviceChainScratchManager::getScratch();
float* scratchBuffer = scratch.getScratchBuffer();
float* tempL = scratch.getTempStereoL();
float* tempR = scratch.getTempStereoR();
float* perFrameGain = scratch.getPerFrameGain();
float* perFramePan = scratch.getPerFramePan();

// DeviceChainAutomationModulation.cpp  
DeviceChainScratch& scratch = DeviceChainScratchManager::getScratch();
float* perFrameGain = scratch.getPerFrameGain();
float* perFramePan = scratch.getPerFramePan();
```

**Header Dependencies**:
- All consumers include `DeviceChainScratchManager.hpp`
- No other headers required for scratch access
- Clear dependency hierarchy (single entry point)

## Testing Requirements

### Unit Test Contract

**Test Harness**:
```cpp
class DeviceChainScratchManagerTest {
public:
    void testThreadLocalStorage() {
        // Verify per-thread isolation
        auto& scratch1 = DeviceChainScratchManager::getScratch();
        auto& scratch2 = DeviceChainScratchManager::getScratch();
        assert(&scratch1 == &scratch2); // Same thread
    }
    
    void testZeroAllocation() {
        // Verify no heap allocations during scratch access
        // Implementation: Run under memory profiler
        // Contract: All scratch access must be allocation-free
    }
    
    void testBufferIntegrity() {
        // Verify scratch buffers are properly initialized
        DeviceChainScratchManager::clearScratch(100);
        // Check all scratch regions are zero
    }
    
    void testPeakCalculation() {
        // Test stereoBlockPeak with known values
        float left[] = {0.1f, 0.5f, -0.8f};
        float right[] = {0.3f, -0.2f, 0.9f};
        float peak = DeviceChainScratchManager::stereoBlockPeak(left, right, 3);
        assert(peak == 0.9f);
    }
};
```

**Test Coverage Requirements**:
- **Thread Safety**: Multiple concurrent AudioThreads
- **Memory Allocation**: Dynamic analysis tools
- **Buffer Bounds**: Overflow/underflow detection
- **Performance**: Sub-microsecond scratch access
- **Integration**: Consumer package compatibility

### Integration Test Contract

**Consumer Integration Validation**:
- **DeviceChainOrchestrator**: Verify audio processing with scratch buffers
- **DeviceChainAutomationModulation**: Verify per-frame gain/pan computation  
- **DeviceChainInstrumentPipeline**: Verify instrument processing with note regions
- **DeviceChainDeviceAdapters**: Verify device adaptation with scratch space

**Performance Benchmarks**:
- **Scratch Access Latency**: Must meet real-time requirements
- **Memory Footprint**: Zero-allocation verification
- **Throughput**: Number of scratch operations per millisecond
- **Stress Test**: Concurrent AudioThread processing

## Acceptance Criteria

### API Contract Compliance
- [ ] All public methods match exact signatures
- [ ] All method contracts are implemented
- [ ] Threading contracts are enforced
- [ ] Error contracts are honored
- [ ] Allocation contracts are verified

### Performance Requirements
- [ ] Scratch access < 100ns
- [ ] Zero allocations during AudioThread execution  
- [ ] Cache-friendly memory layout
- [ ] SIMD-friendly vector operations
- [ ] No function call overhead for hot paths

### Integration Compliance
- [ ] All consumer packages compile and link
- [ ] Scratch manager integration points work correctly
- [ ] No circular dependencies introduced
- [ ] Backward compatibility maintained
- [ ] Integration tests pass

## Upgrade Path

### From DeviceChain.cpp

**Old Scratch Usage**:
```cpp
// Old way (DeviceChain.cpp)
thread_local DeviceChainScratch gScratch;
float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept {
    // ... implementation uses gScratch ...
}
```

**New Way**:
```cpp
// New way (DeviceChainOrchestrator.cpp)
auto& scratch = DeviceChainScratchManager::getScratch();
float stereoBlockPeak(const float* left, const float* right, int frameCount) noexcept {
    // Implementation delegates to DeviceChainScratchManager::stereoBlockPeak
    return DeviceChainScratchManager::stereoBlockPeak(left, right, frameCount);
}
```

**Migration Steps**:
1. Replace direct `gScratch` access with `DeviceChainScratchManager::getScratch()`
2. Replace utility functions with `DeviceChainScratchManager::` versions
3. Remove original DeviceChain.cpp scratch usage
4. Integrate with new scratch management layer

## Conclusion

**API Contract Summary**:
DeviceChainScratchManager provides a precise, binding API contract for thread-local scratch space management. Implementation agents must follow these contracts exactly to ensure compatibility and performance.

**Key Contract Elements**:
1. **Exact Signatures**: No deviations allowed
2. **Threading Safety**: AudioThread-only enforcement
3. **Zero-Allocation**: Hard real-time guarantee
4. **Error Handling**: Graceful input validation
5. **Integration Points**: Single entry point via `getScratch()`

**Implementation Requirements**:
- Complete API implementation without modification
- Full contract compliance testing
- Integration with all consumer work packages
- Performance benchmarking against requirements
- Documentation of contract gaps or risks

**Ready for Implementation**:
This API contract is complete and ready for implementation by assigned work package agents. All requirements, dependencies, and testing specifications are defined.