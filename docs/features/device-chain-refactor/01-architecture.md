# DeviceChain Refactoring Architecture

## User-visible Goal

Refactor the monolithic DeviceChain implementation into focused, single-responsibility components that maintain AudioThread safety and zero-allocation guarantees while dramatically improving code maintainability, testability, and extensibility.

## Non-Goals

- Modify the public API interface
- Change audio processing algorithms or behavior
- Add dynamic allocations to the audio thread
- Replace existing device implementations
- Introduce breaking changes to the audio engine

## Current Code to Reuse

### Core Data Structures
- `DeviceNodePlayback` struct in DeviceChain.hpp
- All parameter structs (`OscillatorParams`, `SamplerParams`, etc.)
- Runtime state structures (`SamplerRuntime`, `SubtractiveSynthRuntime`, etc.)
- `DeviceVariantParams` (std::variant wrapper)
- `TimeBasedEffectRuntime` (with legacy design patterns)

### Helper Functions
- `stereoBlockPeak` - Audio peak calculation utility
- `isDynamicsDeviceNodeKind`, `isInstrumentDeviceNodeKind`, `isFrequencyFxDeviceNodeKind` - Device classification utilities
- `midiActiveFrequencyHz` - MIDI note active detection
- `applyModulation` overloads - Parameter modulation application
- `evaluateAutomationEnvelope`, `applyAutomationValue` - Automation utilities

### Device Implementations
- All device mixing functions in their respective source files
- Device runtime state management
- Biquad filter implementations
- Device-specific processing pipelines

## Proposed Architecture Decision

Split DeviceChain.cpp into 4 focused modules with clear separation of concerns:

### 1. DeviceChainOrchestrator
**Responsibility**: Core audio processing coordination and flow control
- Entry point: `processTrackAudio()`
- Device iteration and dispatch
- Scratch space management coordination
- Integration with automation and LFO systems

### 2. DeviceChainScratchManager
**Responsibility**: Thread-local scratch space management
- Per-AudioThread storage allocation
- Thread-local data management
- Zero-allocation guarantees
- Scratch buffer lifecycle management

### 3. DeviceChainAutomationModulation
**Responsibility**: Per-frame automation and LFO processing
- Timeline automation application
- LFO modulation processing
- Parameter interpolation and modulation
- Per-frame gain/pan computation

### 4. DeviceChainInstrumentPipeline
**Responsibility**: Device-specific processing pipelines
- Instrument (oscillator, sampler, synth) processing
- Dynamics (gate, compressor, expander, limiter) processing
- Time-based effects (delay, reverb, chorus, phaser) processing
- Frequency effects (filter, EQ, frequency shifter) processing

## Module Boundaries

### Processing Layers (Top-down)
1. **Orchestration Layer** (`DeviceChainOrchestrator.cpp`)
   - High-level flow control
   - Device coordination
   - Resource management

2. **Automation Layer** (`DeviceChainAutomationModulation.cpp`)
   - Per-frame parameter updates
   - LFO modulation application
   - Timeline processing

3. **Pipeline Layer** (`DeviceChainInstrumentPipeline.cpp`)
   - Device-specific processing
   - Audio mixing and effects
   - Runtime state management

4. **Resource Layer** (`DeviceChainScratchManager.cpp`)
   - Scratch space allocation
   - Thread-local storage
   - Temporary data management

### Threading Boundaries
- **Audio Thread**: Zero-allocation processing, thread-local storage
- **Control Thread**: Device creation/modification, parameter updates
- **No Cross-Thread Dependencies**: All AudioThread code uses thread-local storage

### Ownership Boundaries
- **Orchestrator Owner**: Core logic, public API coordination
- **Pipeline Owners**: Individual device type processing
- **Resource Owner**: Scratch space, thread-local data
- **Automation Owner**: Timeline and LFO processing

## Threading and Async Boundaries

### Audio Thread (Zero-Allocation)
- All processing runs on AudioThread
- Thread-local storage for shared resources (`gDeviceChainScratch`)
- No dynamic memory allocation
- Reentrant-safe processing

### Control Thread
- Device chain creation and modification
- Parameter updates
- Lifecycle management
- Interaction with Flutter UI layer

### Boundary Protection
- nullptr checks at all public API boundaries
- Thread-local storage guarantees isolation
- No shared mutable state across threads
- Immutability for runtime constants

## Error Model

### Expected Behavior
- No runtime errors during normal operation
- Graceful handling of edge cases (nullptr inputs, empty arrays)
- Clamping of parameter values to valid ranges
- Deterministic behavior for all inputs

### Error Handling
- **Input Validation**: Early returns for nullptr parameters
- **Boundary Checks**: Array bounds validation
- **Parameter Clamping**: Values clamped to valid ranges
- **No Exceptions**: noexcept throughout AudioThread code
- **Debug Assertions**: Developer-level checks in debug builds

## Persistence Model

### Runtime-Only
- DeviceChain is ephemeral (per-track processing)
- No persistence required across sessions
- All state is either runtime or stored in EngineHost

### State Management
- Runtime states stored in parameter structs
- DeviceNodePlayback updated from control thread
- AudioThread reads atomically (single producer, single consumer)

## UI/State Synchronization Model

### Data Flow
1. **Control Thread → Audio Thread**
   - `DeviceNodePlayback` array populated
   - Parameters updated via DeviceNodePlayback
   - Scratch space pre-allocated

2. **Audio Thread → Control Thread**
   - Device meters published via `DeviceMeterAtomic`
   - Audio output available for UI display
   - Meter data is atomic (single write, multiple readers)

### Synchronization Mechanisms
- **Memory Order**: Relaxed atomics for meter updates
- **Pointer Validity**: Device arrays valid for entire AudioThread session
- **Snapshot Pattern**: Control thread writes, AudioThread reads
- **Update Pattern**: Control thread can update between AudioThread blocks

## Development Dependencies

### Required Code (Must exist before implementation)
1. **DeviceChainScratch.hpp** - Scratch storage definition
2. **DeviceChainScratchManager.hpp** - Thread-local storage interface
3. **DeviceChainAutomationModulation.hpp** - Automation/LFO interface
4. **DeviceChainInstrumentPipeline.hpp** - Processing pipeline interface
5. **DeviceChainDeviceAdapters.hpp** - Adapter layer for existing devices

### Existing Code (Will be used)
1. All device mixing functions (in device implementation files)
2. Runtime state structures (in respective headers)
3. Automation envelope functions
4. Parameter modulation functions
5. MIDI utilities

## Quality Gates

### Code Quality
- File size: < 300 LOC (per file, except implementation details)
- Function size: < 40 LOC (per function)
- Nesting depth: ≤ 3 levels
- Public API: Small and intentional
- Single responsibility: Each class has one clear purpose

### Testing
- Unit tests for each component
- Integration tests for cross-component interaction
- Performance benchmarks
- Memory leak detection
- Thread safety verification

### Performance
- Zero allocations on AudioThread
- Processing time < current implementation
- Memory usage < current implementation
- No CPU pipeline stalls

## Integration Risks

### High Risk
- **Interface Compatibility**: WP-05 adapters must preserve exact device behavior
- **Performance**: New interface may introduce overhead
- **Memory Alignment**: Scratch space size must be correct for all use cases

### Medium Risk
- **Thread Safety**: Thread-local storage must be properly initialized
- **Parameter Passing**: Complex parameter passing between components

### Low Risk
- **Build Integration**: New headers must be correctly included
- **Code Generation**: Need to ensure all device types are covered

## Technical Debt Management

### Short-term Debt
- Adapter layer complexity (required for backward compatibility)
- Interface translation overhead

### Long-term Opportunities
- Future device additions become trivial
- Component testing enables isolated bug fixing
- Code review becomes more focused
- Documentation becomes self-documenting

## Success Criteria

### Definition of Done
- All components implemented according to contracts
- All existing tests pass (behavioral compatibility)
- New unit tests cover each component
- Performance benchmarks met
- Code quality gates satisfied
- Documentation complete and maintained
- AudioThread zero-allocation guarantees verified
- Thread safety verified
- Build system working correctly

### Acceptance Criteria
- Audio output identical to original implementation
- No crashes or memory corruption
- Performance within 5% of baseline
- All existing device types work correctly
- UI remains fully functional
- No regression in features
- Code review passes with minimal comments
- Technical debt within acceptable limits