# DeviceChain Refactoring - Canonical Vocabulary

## Purpose

This document defines the canonical vocabulary for the DeviceChain refactoring. All implementation agents must use these exact names and cannot invent synonyms or alternative names.

## Usage Guidelines

- **Exact Names**: Implement the canonical names exactly as defined
- **No Synonyms**: Do not create alternative names for the same concepts
- **Interface Consistency**: All public APIs must match the contract exactly
- **File Naming**: Use the specified file names for new implementations

## Canonical Vocabulary Table

| Concept | Canonical name | Type/file | Notes |
|---------|----------------|-----------|-------|
| Core orchestrator | `DeviceChainOrchestrator` | `include/audioapp/DeviceChainOrchestrator.hpp` | Main audio processing coordinator |
| Scratch storage | `DeviceChainScratchManager` | `include/audioapp/DeviceChainScratchManager.hpp` | Thread-local scratch space management |
| Thread-local scratch | `gDeviceChainScratch` | `src/DeviceChainScratchManager.cpp` | Global thread-local scratch instance |
| Automation processing | `DeviceChainAutomationModulation` | `include/audioapp/DeviceChainAutomationModulation.hpp` | Per-frame automation and LFO processing |
| Instrument pipeline | `DeviceChainInstrumentPipeline` | `include/audioapp/DeviceChainInstrumentPipeline.hpp` | Device-specific processing pipelines |
| Device adapters | `DeviceChainDeviceAdapters` | `include/audioapp/DeviceChainDeviceAdapters.hpp` | Interface adapters for existing devices |
| Public API | `processTrackAudio` | `include/audioapp/DeviceChainOrchestrator.hpp` | Entry point for audio processing |
| Scratch struct | `DeviceChainScratch` | `include/audioapp/DeviceChainScratch.hpp` | Container for all scratch arrays and temporary storage |
| Automation method | `applyAutomationAtFrame` | `include/audioapp/DeviceChainAutomationModulation.hpp` | Timeline automation processing |
| LFO method | `applyLfoModulationAtFrame` | `include/audioapp/DeviceChainAutomationModulation.hpp` | LFO modulation processing |
| Per-frame gain/pan | `computePerFrameGainPan` | `include/audioapp/DeviceChainAutomationModulation.hpp` | Compute per-frame gain and pan values |
| Instrument mixing | `mixInstrumentBlock` | `include/audioapp/DeviceChainInstrumentPipeline.hpp` | Instrument-specific audio generation |
| Dynamics processing | `processDynamicsBlock` | `include/audioapp/DeviceChainInstrumentPipeline.hpp` | Gate/compressor/expander/limiter processing |
| Time effects | `processTimeBasedEffectBlock` | `include/audioapp/DeviceChainInstrumentPipeline.hpp` | Delay/reverb/chorus/phaser processing |
| Frequency effects | `processFrequencyEffectBlock` | `include/audioapp/DeviceChainInstrumentPipeline.hpp` | Filter/EQ/frequency shifter processing |
| MIDI note utility | `midiActiveFrequencyHz` | `include/audioapp/DeviceChainOrchestrator.hpp` | Core utility function for MIDI note detection |
| Audio peak utility | `stereoBlockPeak` | `include/audioapp/DeviceChainScratchManager.hpp` | Audio peak calculation utility |
| Device classification | `isDynamicsDeviceNodeKind` | `include/audioapp/DeviceChainOrchestrator.hpp` | Device kind classification utility |
| Runtime states | `SamplerRuntime`, `SubtractiveSynthRuntime`, etc. | Various device headers | Per-device runtime state structures |
| Parameter types | `OscillatorParams`, `SamplerParams`, etc. | `include/audioapp/DeviceChain.hpp` | Per-device parameter structs |
| Device kind enum | `DeviceNodeKind` | `include/audioapp/DeviceChain.hpp` | Enum of all device types |
| Node definition | `DeviceNodePlayback` | `include/audioapp/DeviceChain.hpp` | Per-device runtime state for audio thread |
| Automation points | `AutomationPointState` | `include/audioapp/AutomationTypes.hpp` | Automation envelope point data |
| Modulation edges | `ModulationEdgePlayback` | `include/audioapp/AutomationTypes.hpp` | LFO modulation edge data |
| LFO values array | `lfoValues` | Various headers | LFO output values for processing |
| Automation clips | `AutomationClipPlayback` | `include/audioapp/AutomationTypes.hpp` | Timeline automation clip data |
| Meter storage | `DeviceMeterAtomic` | `include/audioapp/DeviceChain.hpp` | Atomic meter storage for visualization |
| Oscillator phase | `oscillatorPhase` | Various headers | Phase state for oscillator generation |
| Parameter variant | `DeviceVariantParams` | `include/audioapp/DeviceChain.hpp` | Union type for device parameters |

## Forbidden Names/Synonyms

### Do NOT Create These:
- `ScratchManager` instead of `DeviceChainScratchManager`
- `AudioProcessor` instead of `DeviceChainOrchestrator`  
- `EffectProcessor` instead of `DeviceChainInstrumentPipeline`
- `AutomationProcessor` instead of `DeviceChainAutomationModulation`
- `DeviceAdapter` instead of `DeviceChainDeviceAdapters`
- `gScratch` instead of `gDeviceChainScratch`
- `trackProcessor` instead of `processTrackAudio`
- `applyEnvelope` instead of `applyAutomationAtFrame`
- `applyLFO` instead of `applyLfoModulationAtFrame`
- `mixBlock` instead of `mixInstrumentBlock`
- `processEffect` instead of `processDynamicsBlock` (or other specific effects)

## Naming Conventions

### File Naming
- **New files**: Use exact names as specified in vocabulary table
- **Implementation files**: `.cpp` for implementation, `.hpp` for headers
- **Directory structure**: Maintain existing directory structure

### Class Naming
- **Orchestrator**: `DeviceChainOrchestrator`
- **Manager**: `DeviceChainScratchManager`
- **Processing**: `DeviceChainAutomationModulation`, `DeviceChainInstrumentPipeline`
- **Adapters**: `DeviceChainDeviceAdapters`

### Method Naming
- **Public API**: `processTrackAudio`, `applyAutomationAtFrame`, `applyLfoModulationAtFrame`, `computePerFrameGainPan`
- **Private API**: `getScratch()`, `scratch()`
- **Pipeline methods**: `mixInstrumentBlock`, `processDynamicsBlock`, `processTimeBasedEffectBlock`, `processFrequencyEffectBlock`

### Variable Naming
- **Global/static**: `gDeviceChainScratch`
- **Thread-local**: Same as above
- **Parameter names**: Follow existing naming conventions in DeviceChain.cpp
- **Internal**: Match parameter names in original DeviceChain.cpp

## Responsibility Assignment

### Component Responsibilities
| Component | Core Responsibility | Public Methods | Private Methods |
|-----------|-------------------|----------------|----------------|
| `DeviceChainOrchestrator` | Core audio processing coordination | `processTrackAudio()` | `getScratch()`, `computePerFrameGainPan()` |
| `DeviceChainScratchManager` | Thread-local scratch space | N/A | `getScratch()`, `scratch()` |
| `DeviceChainAutomationModulation` | Per-frame automation/LFO | `applyAutomationAtFrame()`, `applyLfoModulationAtFrame()`, `computePerFrameGainPan()` | Various helper functions |
| `DeviceChainInstrumentPipeline` | Device-specific processing | `mixInstrumentBlock()`, `processDynamicsBlock()`, `processTimeBasedEffectBlock()`, `processFrequencyEffectBlock()` | Device-specific helpers |
| `DeviceChainDeviceAdapters` | Interface adaptation | Adapter entry points, wrapper functions | Type conversion helpers |

## Integration Rules

### Cross-Component Dependencies
- **Orchestrator depends on**: ScratchManager, AutomationModulation, InstrumentPipeline
- **InstrumentPipeline depends on**: DeviceChainDeviceAdapters
- **All components use**: DeviceNodePlayback, DeviceVariantParams, DeviceMeterAtomic

### Data Flow Rules
1. **Orchestrator → ScratchManager**: Get scratch space reference
2. **Orchestrator → AutomationModulation**: Process automation at frame
3. **Orchestrator → InstrumentPipeline**: Process each device
4. **AutomationModulation → InstrumentPipeline**: Provide computed gain/pan, modulation
5. **InstrumentPipeline → Orchestrator**: Return mixed audio

### Communication Protocols
- **Shared data**: Use DeviceNodePlayback for device state
- **Parameters**: Use DeviceVariantParams for device parameters
- **Runtime states**: Use respective runtime structures
- **Scratch space**: Thread-local via DeviceChainScratchManager

## Version Control Notes

### Protected Files (No Changes)
- `include/audioapp/DeviceChain.hpp` - Read-only (contains core types)
- `include/audioapp/AutomationTypes.hpp` - Read-only (automation data)
- All device implementation files (.cpp in device families) - Read-only (only called, not modified)
- `src/DeviceChain.cpp` - Read-only (original implementation)

### Editable Files
- All new files must use canonical names exactly
- Implementation details can vary within component boundaries
- Interface adapters must maintain exact function signatures

## Compliance Verification

### Implementation Requirements
1. **Naming compliance**: All public APIs must use canonical names
2. **Interface compliance**: Method signatures must match contracts exactly
3. **Responsibility compliance**: Components must have single, clear responsibilities
4. **Dependency compliance**: Dependencies must follow the defined flow
5. **Usage compliance**: No synonyms or alternative names for canonical concepts

### Review Checklist
- [ ] All component names match canonical names
- [ ] Public API method names match exactly
- [ ] Variable names follow naming conventions
- [ ] File names match canonical names
- [ ] No forbidden synonyms used anywhere
- [ ] Cross-component dependencies correct
- [ ] Data flow matches architecture documentation
- [ ] Thread safety boundaries respected

## Maintenance Notes

### When to Update
- **Vocabulary changes**: Only during major version releases
- **Component splits**: When SRP violations are identified
- **Interface changes**: Only with full integration testing
- **Name changes**: Never without migration strategy

### Deprecated Names
- Any non-canonical names found in implementation must be updated
- Synonyms must be migrated to canonical names
- Legacy code must use migration adapters

## Legal/Attribution Notes

### Third-party Dependencies
- All device implementations remain owned by their respective component teams
- Interface adapters preserve existing device behavior exactly
- No changes to device public APIs
- All device implementations continue to be maintained separately

### Code Ownership
- New components owned by core audio team
- Device adapters owned by device implementation teams
- Orchestrator owned by core audio team
- Scratch manager owned by core audio team
- Automation/modulation owned by core audio team
- Instrument pipeline owned by core audio team

This canonical vocabulary ensures consistency across parallel implementation by multiple subagents working on the DeviceChain refactoring.