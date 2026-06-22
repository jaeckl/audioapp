# DeviceChain Refactoring - Vertical Work Packages

## Overview

This document defines the vertical work packages for the DeviceChain refactoring. Each work package represents an end-to-end, independently understandable piece of functionality that can be implemented and tested in isolation.

## Package Architecture Principles

### Vertical Slice Design
- **End-to-End Behavior**: Each package must deliver complete, user-visible functionality
- **Independent Testing**: Packages can be tested in isolation without integration dependencies
- **Clear Boundaries**: Well-defined inputs and outputs between packages
- **No Horizontal Work**: Avoid packages that span multiple layers or concerns

### Package Classification
- **Parallel-Safe**: Can run simultaneously without dependencies
- **Parallel-Safe After Stubs**: Can run in parallel after minimal prerequisite packages exist
- **Sequential Dependency**: Must wait for other packages to complete first
- **Integration-Only**: Package only coordinates other packages

## Vertical Work Package Details

### WP-01: DeviceChain Orchestrator Core

#### User-Visible Behavior
Audio track processing that coordinates instrument, dynamics, and effect chains to produce output audio.

#### Acceptance Criteria
- Complete `processTrackAudio()` implementation
- All devices processed correctly (instruments, dynamics, effects)
- Identical audio output to original implementation
- Zero-allocation AudioThread safety verified
- Thread safety validated

#### Assigned Files
- `include/audioapp/DeviceChainOrchestrator.hpp`
- `src/DeviceChainOrchestrator.cpp`
- `src/DeviceChainOrchestrator_impl.cpp`

#### Forbidden Files
- All device implementation files (.cpp in device families)
- Existing `DeviceChain.cpp`
- `EngineHost.cpp`

#### Canonical Names Used
- `DeviceChainOrchestrator::processTrackAudio`
- `DeviceChainScratchManager::getScratch()`
- `midiActiveFrequencyHz`
- `stereoBlockPeak`
- `DeviceNodePlayback`
- `DeviceVariantParams`

#### API/Data Contracts Used
- All runtime state structures (`SamplerRuntime`, `SubtractiveSynthRuntime`, etc.)
- `DeviceNodePlayback` struct
- `DeviceVariantParams` union
- `MidiPlaybackNote` events
- `DeviceMeterAtomic` structures

#### Dependencies
- `DeviceChainScratchManager` (scratch space)
- `DeviceChainAutomationModulation` (automation/LFO processing)
- `DeviceChainInstrumentPipeline` (device processing)
- `DeviceChainDeviceAdapters` (device interface adapters)

#### Required Tests
- Integration test comparing outputs frame-by-frame with original
- Thread safety stress test (multiple AudioThreads)
- Null pointer safety test
- Performance benchmark vs original
- Memory usage verification

#### Manual Verification Steps
1. Render a complex sequence (instruments + dynamics + effects)
2. Compare audio output with original implementation (spectral analysis)
3. Monitor CPU usage and memory footprint
4. Verify no crashes under stress (continuous processing)

#### Integration Risk
- **Severity**: Medium (affects all audio processing)
- **Impact**: High (core orchestration affects all downstream packages)
- **Mitigation**: Strict testing of cross-package interfaces

#### Parallel Capability
- **Classification**: Sequential Dependency
- **Reason**: Depends on all other work packages

### WP-02: Scratch Space Management

#### User-Visible Behavior
Thread-safe management of per-AudioThread scratch space for temporary audio processing, ensuring zero-allocation guarantees.

#### Acceptance Criteria
- Thread-local storage works correctly
- No memory leaks or buffer overflows
- Zero-allocation verified under load
- Scratch space sufficiently sized for all use cases
- Thread safety validated

#### Assigned Files
- `include/audioapp/DeviceChainScratch.hpp`
- `include/audioapp/DeviceChainScratchManager.hpp`
- `src/DeviceChainScratchManager.cpp`

#### Forbidden Files
- All other DeviceChain related files
- Threading utilities outside DeviceChain

#### Canonical Names Used
- `gDeviceChainScratch`
- `DeviceChainScratchManager::getScratch()`
- `DeviceChainScratch`

#### API/Data Contracts Used
- All scratch buffer types (`samplerRegions`, `perFrameGain`, etc.)
- Scratch buffer size constants (`kScratchFrames`, `kMaxInstrumentRegions`)
- Thread-local storage patterns

#### Dependencies
- **Dependencies**: None (foundational layer)
- **Provided To**: WP-01, WP-03, WP-04

#### Required Tests
- Thread safety test (concurrent AudioThreads)
- Memory allocation verification (dynamic analysis tools)
- Performance benchmark
- Buffer overflow detection
- Scratch space integrity validation

#### Manual Verification Steps
1. Render multiple simultaneous tracks (50 concurrent AudioThreads)
2. Verify no race conditions (thread sanitizer output)
3. Check memory footprint (memory profiler)
4. Validate scratch buffer integrity (fuzz testing)

#### Integration Risk
- **Severity**: Low (shared resource foundation)
- **Impact**: High (all packages depend on it)
- **Mitigation**: Comprehensive thread safety testing

#### Parallel Capability
- **Classification**: Parallel-Safe
- **Reason**: No file dependencies, shared but read-only access after creation

### WP-03: Automation and LFO Processing

#### User-Visible Behavior
Per-frame automation timeline updates and LFO modulation application for dynamic parameter control.

#### Acceptance Criteria
- Automation curves applied correctly (precision validation)
- LFO modulation timing accurate (phase and amplitude)
- Edge case handling (null inputs, empty arrays, boundary conditions)
- Parameter clamping correct (range enforcement)
- Integration with navigation and scrubbing workflows

#### Assigned Files
- `include/audioapp/DeviceChainAutomationModulation.hpp`
- `src/DeviceChainAutomationModulation.cpp`

#### Forbidden Files
- Existing DeviceChain.cpp automation/modulation logic
- Device-specific automation handling

#### Canonical Names Used
- `DeviceChainAutomationModulation::applyAutomationAtFrame`
- `DeviceChainAutomationModulation::applyLfoModulationAtFrame`
- `evaluateAutomationEnvelope`
- `applyAutomationValue`
- `ModulationEdgePlayback`
- `AutomationClipPlayback`

#### API/Data Contracts Used
- `AutomationClipPlayback` timeline clips
- `ModulationEdgePlayback` LFO edges
- `DeviceVariantParams` (modified in-place)
- `AutomationPointState` control points
- Parameter IDs (`kEncodedCommonGain`, etc.)

#### Dependencies
- **Dependencies**: `DeviceChain.hpp` (automation types), existing helper functions
- **Provided To**: WP-01

#### Required Tests
- Automation curve precision test (sub-sample accuracy)
- LFO phase and modulation depth test (timing accuracy)
- Interleaved automation/LFO test (combined effects)
- Boundary condition test (empty arrays, null pointers)
- Parameter clamping validation (range enforcement)

#### Manual Verification Steps
1. Set automation for multiple parameters (gain, pan, filter cutoff, etc.)
2. Apply LFO modulation with various waveforms and depths
3. Capture processed audio (multiple automation scenarios)
4. Verify automation curves match expected values (analytic verification)

#### Integration Risk
- **Severity**: Medium (affects parameter processing accuracy)
- **Impact**: Medium (all devices use automated parameters)
- **Mitigation**: Precision testing and validation

#### Parallel Capability
- **Classification**: Parallel-Safe
- **Reason**: No file dependencies, can be implemented independently

### WP-04: Instrument Pipeline Processing

#### User-Visible Behavior
High-performance processing of instrument, dynamics, and time/frequency effects with optimized audio mixing and effects chains.

#### Acceptance Criteria
- All device types processed correctly (oscillators, samplers, synths, generators)
- Audio quality matches original implementation (perceptual testing)
- Performance meets or exceeds original (timing and throughput)
- No memory allocations during AudioThread
- Integration with automation and effects complete

#### Assigned Files
- `include/audioapp/DeviceChainInstrumentPipeline.hpp`
- `src/DeviceChainInstrumentPipeline.cpp`

#### Forbidden Files
- All device family implementation files (until adapters exist)
- Original DeviceChain.cpp switch logic
- Device runtime state definitions

#### Canonical Names Used
- `DeviceChainInstrumentPipeline::mixInstrumentBlock`
- `DeviceChainInstrumentPipeline::processDynamicsBlock`
- `DeviceChainInstrumentPipeline::processTimeBasedEffectBlock`
- `DeviceChainInstrumentPipeline::processFrequencyEffectBlock`
- `DeviceChainDeviceAdapters` (integration point)
- All device mixing functions (externally called)

#### API/Data Contracts Used
- All device parameter structs (`OscillatorParams`, `SamplerParams`, etc.)
- All runtime state structures (`SamplerRuntime`, `DynamicsRuntime`, etc.)
- Device mixing functions (from existing device files)
- `BiquadState`, `SubtractiveSynthRuntime`, etc.
- Scratch space interfaces

#### Dependencies
- **Dependencies**: `DeviceChainDeviceAdapters` (interface adapters)
- **Provided To**: WP-01

#### Required Tests
- Instrument processing test for each device type (31 device types)
- Dynamics processing validation (gate, compressor, expander, limiter)
- Effect processing accuracy test (delay, reverb, chorus, phaser, filter, EQ, frequency shifter)
- Integration test with automation/LFO (combined processing)
- Performance comparison vs original
- Memory allocation monitoring

#### Manual Verification Steps
1. Create tracks with all device types (31 different device kinds)
2. Render complex sequences (instruments + dynamics + all effects)
3. Compare output with baseline (spectral and waveform analysis)
4. Verify no glitches or dropouts (continuous processing test)
5. Stress test with many devices (50+ devices simultaneous)

#### Integration Risk
- **Severity**: High (core audio processing functionality)
- **Impact**: High (all device processing)
- **Mitigation**: Comprehensive adapter testing and behavior validation

#### Parallel Capability
- **Classification**: Parallel-Safe After Stubs
- **Reason**: Requires `DeviceChainDeviceAdapters` package first

### WP-05: Device Interface Adapters

#### User-Visible Behavior
Adapt existing device implementations to new orchestrator interface while preserving exact behavior and maintaining AudioThread safety.

#### Acceptance Criteria
- All device types can be called via new interface (31 device types)
- No changes to existing device behavior (behavioral equivalence)
- Zero-allocation during AudioThread
- Correct data flow between pipeline and devices
- Comprehensive adapter coverage

#### Assigned Files
- `include/audioapp/DeviceChainDeviceAdapters.hpp`
- `src/DeviceChainDeviceAdapters.cpp`

#### Forbidden Files
- Original DeviceChain.cpp
- Device implementation files (except for header inclusion)

#### Canonical Names Used
- `DeviceChainInstrumentPipeline::mixInstrumentBlock` (adapter entry point)
- All existing device mixing functions (externally called)
- Adapter wrapper methods

#### API/Data Contracts Used
- Existing device mixing function signatures
- Pipeline-specific data structures
- Scratch space interfaces
- Runtime state structures

#### Dependencies
- **Dependencies**: All device implementation files, `DeviceChainInstrumentPipeline`
- **Provided To**: WP-04

#### Required Tests
- Device adapter unit tests (for each device type)
- Integration with pipeline test (end-to-end adapter usage)
- Performance comparison (adapter overhead)
- Memory usage verification (allocation monitoring)
- Behavior preservation test (frame-by-frame comparison)

#### Manual Verification Steps
1. Create adapter test harness (wrapper around each device)
2. Mix each device type via adapter (31 device types)
3. Compare results with direct calls (behavioral equivalence)
4. Stress test with many devices (performance and memory)

#### Integration Risk
- **Severity**: Medium (interface compatibility)
- **Impact**: High (all device processing)
- **Mitigation**: Extensive behavioral validation

#### Parallel Capability
- **Classification**: Parallel-Safe
- **Reason**: Can be implemented independently, enables WP-04

## Parallelization Summary

### Phase 1: Parallel-Safe (No Dependencies)
1. **WP-02**: Scratch Space Management
   - Foundation layer, no dependencies
   - Provides critical resource for all other packages

2. **WP-03**: Automation and LFO Processing
   - Independent processing logic
   - No file dependencies or shared state
   - Can be implemented and tested in isolation

### Phase 2: Parallel-Safe After Prerequisites
1. **WP-05**: Device Interface Adapters
   - Can be implemented after identifying all device types
   - No dependencies on orchestrator or pipeline
   - Enables WP-04

2. **WP-04**: Instrument Pipeline Processing
   - Requires `DeviceChainDeviceAdapters` for interface
   - Can be implemented once adapters exist
   - Core processing logic

### Phase 3: Sequential Dependencies
1. **WP-01**: DeviceChain Orchestrator
   - Must wait for all other packages to complete
   - Integrates all processing components
   - Core orchestration logic

## Package Interactions

### Data Flow Chain
1. **WP-02 provides**: Scratch space (`gDeviceChainScratch`)
2. **WP-03 provides**: Per-frame gain/pan, parameter modulation
3. **WP-05 provides**: Adapter interface to original devices
4. **WP-04 uses**: All of the above to process each device
5. **WP-01 coordinates**: Everything for track processing

### Interface Contracts
1. **DeviceNodePlayback**: Read-only contract shared by all packages
2. **DeviceVariantParams**: Parameter contract used by WP-03, WP-04
3. **Runtime States**: Used by WP-04 (instrument pipeline)
4. **Scratch Space**: Managed by WP-02, used by WP-04
5. **Automation Types**: Used by WP-03

### Shared File Access
- **Read-Only Shared**: Core type definitions (DeviceChain.hpp, AutomationTypes.hpp)
- **Read-Write Shared**: Runtime states (initialized by control thread, modified by AudioThread)
- **Thread-Local Shared**: Scratch space (WP-02, accessed by WP-01, WP-03, WP-04)

## Integration Testing Requirements

### Package Integration Tests
1. **WP-01 Integration**: Verify orchestrator coordinates all components correctly
2. **WP-02 Integration**: Verify scratch space works across all packages
3. **WP-03 Integration**: Verify automation/LFO affects all device processing
4. **WP-04 Integration**: Verify pipeline processes all device types via adapters
5. **WP-05 Integration**: Verify adapters correctly wrap all device implementations

### Cross-Package Validation
- Audio output consistency across all packages
- Memory usage validation for concurrent processing
- Thread safety verification across package boundaries
- Performance regression detection
- Behavioral equivalence with original implementation

## Development Order Recommendations

### Recommended Implementation Sequence
1. **Week 1-2**: WP-02 (Scratch Space Management)
   - Implement thread-local storage
   - Comprehensive testing
   - Performance optimization

2. **Week 3-4**: WP-03 (Automation and LFO)
   - Implement automation processing
   - LFO modulation logic
   - Parameter testing

3. **Week 5-6**: WP-05 (Device Interface Adaptors)
   - Create adapters for all 31 device types
   - Behavioral validation
   - Performance comparison

4. **Week 7-8**: WP-04 (Instrument Pipeline)
   - Implement core pipeline logic
   - Integrate with adapters
   - Pipeline optimization

5. **Week 9-10**: WP-01 (Orchestrator Core)
   - Implement main audio processing flow
   - Coordinate all packages
   - End-to-end integration testing

### Risk Mitigation
- **Risk 1**: Scratch space implementation delays → Phase 1 adjustment
- **Risk 2**: Adapter implementation issues → Extended Phase 3 timeline
- **Risk 3**: Performance regressions → Comprehensive benchmarking
- **Risk 4**: Behavioral incompatibility → Frame-by-frame validation

## Success Metrics

### Package-Specific Metrics
- **WP-01**: 100% behavioral compatibility, < 5% performance degradation
- **WP-02**: Zero allocations, thread safety verified
- **WP-03**: Sub-sample precision, edge case coverage
- **WP-04**: All device types functional, performance targets met
- **WP-05**: Exact behavioral equivalence to original devices

### System-Wide Metrics
- **Integration**: All packages integrated successfully
- **Testing**: 100% test coverage for new code
- **Performance**: End-to-end processing < current implementation
- **Memory**: Zero allocations in AudioThread
- **Compatibility**: Drop-in replacement for existing DeviceChain

## Estimated Timeline

### Development Timeline (10 weeks)
- **Weeks 1-4**: Foundation packages (WP-02, WP-03)
- **Weeks 5-6**: Adapter layer (WP-05)
- **Weeks 7-8**: Processing pipeline (WP-04)
- **Weeks 9-10**: Orchestrator integration (WP-01)
- **Weeks 11-12**: Integration testing and validation

### Testing Timeline
- **Unit Testing**: 4 weeks (packages can test in parallel)
- **Integration Testing**: 2 weeks (requires all packages)
- **Performance Testing**: 2 weeks (requires complete system)
- **Regression Testing**: 1 week (behavioral validation)

This vertical work package structure enables parallel implementation of multiple independent teams while ensuring proper integration and behavioral compatibility with the original DeviceChain implementation.