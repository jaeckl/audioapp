# OOP Device Processors Phase 2 — Vertical Work Packages

This document defines 8 work packages. Each is a vertical slice: end-to-end from infrastructure through processor migration to integration.

---

## Package P0: Infrastructure & Base Classes (Sequential — must run first)

**Behavior**: Create the abstract base class, AudioBlock, ProcessContext, ProcessorArena, DeviceChainOrchestrator (stubs + implementation), DeviceChainScratchArena, and update CMakeLists.txt. After P0, the project compiles and all existing tests pass (old path still active).

**Files Assigned**:
- Create: `engine_juce/include/audioapp/devices/processors/DeviceProcessor.hpp`
- Create: `engine_juce/include/audioapp/devices/processors/AudioBlock.hpp`
- Create: `engine_juce/include/audioapp/devices/processors/ProcessContext.hpp`
- Create: `engine_juce/include/audioapp/devices/processors/ProcessorArena.hpp`
- Create: `engine_juce/src/devices/processors/ProcessorArena.cpp`
- Create: `engine_juce/include/audioapp/DeviceChainOrchestrator.hpp`
- Create: `engine_juce/src/DeviceChainOrchestrator.cpp` (empty stub — `processChain` returns immediately)
- Modify: `engine_juce/include/audioapp/DeviceChainScratch.hpp` (add DeviceChainScratchArena)
- Modify: `engine_juce/CMakeLists.txt` (add new .cpp files)

**Forbidden Files**: Any processor .hpp or .cpp (P1-P6 territory), DeviceChainProcessor.cpp, DeviceChain.cpp, ProjectEngine.hpp

**Canonical Names Used**: `DeviceProcessor`, `AudioBlock`, `ProcessContext`, `ProcessorArena`, `DeviceChainOrchestrator`, `DeviceChainScratchArena`

**Dependencies**: None (runs first)

**Acceptance Criteria**:
- Project compiles with `tools/step_gate.py`
- All existing tests pass (old processing path unchanged)
- New headers can be included without errors

**Parallel-Safe**: No — must run first

---

## Package P1: Utility Processor (Parallel-Safe after P0)

**Behavior**: Convert `TrackGainProcessor` from static-method class to `DeviceProcessor` subclass. This is the simplest processor — no runtime state, no meters.

**Files Assigned**:
- Modify: `engine_juce/include/audioapp/devices/processors/TrackGainProcessor.hpp`
- Modify: `engine_juce/src/devices/processors/TrackGainProcessor.cpp`

**Forbidden Files**: Any other processor files, DeviceChainProcessor.cpp, DeviceChain.cpp, ProjectEngine.hpp

**Canonical Names Used**: `TrackGainProcessor : DeviceProcessor`

**API/Data Contracts**: `process(AudioBlock& block, ProcessContext& ctx)` — applies gain from node (via `ctx`). The orchestrator will apply perFrameGain; TrackGain's job is to set the track buffer level.

**Acceptance Criteria**:
- TrackGainProcessor compiles as subclass
- Output identical to Phase 1 for same inputs

**Parallel-Safe**: Yes — independently compilable after P0

---

## Package P2: Synthesizers (Parallel-Safe after P0)

**Behavior**: Convert `OscillatorProcessor`, `SamplerProcessor`, `SubtractiveSynthProcessor`, `BassSynthProcessor`, and `PhaseModSynthProcessor` to `DeviceProcessor` subclasses. Each owns its runtime as a member (no external arrays).

**Files Assigned**:
- Modify: `.../OscillatorProcessor.hpp` + `.cpp`
- Modify: `.../SamplerProcessor.hpp` + `.cpp`
- Modify: `.../SubtractiveSynthProcessor.hpp` + `.cpp`
- Modify: `.../PhaseModSynthProcessor.hpp` + `.cpp`

Note: `BassSynthProcessor` still delegates to `SubtractiveSynthProcessor` — no separate subclass needed (it's a re-entry point, not a separate object).

**Forbidden Files**: All other files.

**Canonical Names**: Each processor as `FooProcessor : DeviceProcessor`

**Key state migrations**:
- `OscillatorProcessor` gains `float oscillatorPhase_`
- `SamplerProcessor` gains `BiquadState samplerFilterStates_[kMaxInstrumentRegions]`
- `SubtractiveSynthProcessor` gains `SubtractiveSynthRuntime runtime_`
- `PhaseModSynthProcessor` gains `PhaseModSynthRuntime runtime_`

**Acceptance Criteria**:
- Each processor produces bit-identical output to Phase 1
- Individual test compilation passes (if test files are built)

**Parallel-Safe**: Yes — files are independent

---

## Package P3: Percussion Generators (Parallel-Safe after P0)

**Behavior**: Convert `KickProcessor`, `SnareProcessor`, `ClapProcessor`, `CymbalProcessor`, and `CrashProcessor` to `DeviceProcessor` subclasses.

**Files Assigned**:
- Modify: all 5 percussion processor .hpp + .cpp files

**Forbidden Files**: All other files.

**Canonical Names**: `KickProcessor : DeviceProcessor`, `SnareProcessor : DeviceProcessor`, etc.

**Key state migrations**:
- Each gains its respective `*GeneratorRuntime runtime_` member

**Parallel-Safe**: Yes — files are independent

---

## Package P4: Dynamics Effects (Parallel-Safe after P0)

**Behavior**: Convert `GateProcessor`, `CompressorProcessor`, `ExpanderProcessor`, and `LimiterProcessor` to `DeviceProcessor` subclasses.

**Files Assigned**:
- Modify: all 4 dynamics processor .hpp + .cpp files

**Forbidden Files**: All other files.

**Canonical Names**: `GateProcessor : DeviceProcessor`, `CompressorProcessor : DeviceProcessor`, etc.

**Key state migrations**:
- Each gains `DynamicsRuntime runtime_` member
- Meter publishing via `ctx.deviceMeters` (same logic, different access path)

**Parallel-Safe**: Yes — files are independent

---

## Package P5: Time-Based Effects (Parallel-Safe after P0)

**Behavior**: Convert `DelayProcessor`, `ReverbProcessor`, `ChorusProcessor`, and `PhaserProcessor` to `DeviceProcessor` subclasses. Each **removes heap allocation** (`new float[192000]`) and uses `DeviceChainScratchArena` ring buffers instead.

**Files Assigned**:
- Modify: all 4 time-based processor .hpp + .cpp files

**Forbidden Files**: All other files.

**Canonical Names**: `DelayProcessor : DeviceProcessor`, `ReverbProcessor : DeviceProcessor`, etc.

**Key changes**:
- No `TimeBasedEffectRuntime` at all
- Each processor owns: `float* bufferLeft_`, `float* bufferRight_`, `int writeIndex_`, `float lfoPhase_`
- `PhaserProcessor` additionally owns `float phaserStateL_[4]`, `float phaserStateR_[4]`
- Buffers populated during `initParams()` from `ringBufferArena.allocate()`
- `initParams()` must be non-trivial (allocates + zeroes buffers)

**Parallel-Safe**: Yes — files are independent, but note: `DeviceChainScratchArena` must be finalized in P0 first.

---

## Package P6: Frequency FX (Parallel-Safe after P0)

**Behavior**: Convert `FilterProcessor`, `FourBandEqProcessor`, and `FrequencyShifterProcessor` to `DeviceProcessor` subclasses.

**Files Assigned**:
- Modify: all 3 frequency FX processor .hpp + .cpp files

**Forbidden Files**: All other files.

**Key state migrations**:
- `FilterProcessor` gains `FilterRuntime runtime_`
- `FourBandEqProcessor` gains `FourBandEqRuntime runtime_`
- `FrequencyShifterProcessor` gains `FrequencyShifterRuntime runtime_`

**Parallel-Safe**: Yes — files are independent

---

## Package P7: Orchestrator Integration (Sequential — runs last)

**Behavior**: Wire the new OOP processors into the audio processing pipeline:
1. Implement `buildProcessorChain()` — factory that populates `ProcessorArena` from `DeviceNodePlayback[]`
2. Implement `DeviceChainOrchestrator::processChain()` — the new loop
3. Update `DeviceChainProcessor.cpp` to delegate to the new orchestrator (or mark deprecated)
4. Update `DeviceChain.cpp` to use the new orchestrator
5. Update `ProjectEngine.hpp` — remove all 9 parallel runtime arrays, add `ProcessorArena`
6. Update `ProjectEngine.cpp` — use new build/process flow
7. Remove/comment the old 33-param `processDeviceNode` function

**Files Assigned**:
- Complete: `engine_juce/src/DeviceChainOrchestrator.cpp` (full implementation)
- Modify: `engine_juce/src/DeviceChainProcessor.cpp` (mark as deprecated wrapper)
- Modify: `engine_juce/src/DeviceChain.cpp` (replace orchestrator loop)
- Modify: `engine_juce/include/audioapp/ProjectEngine.hpp` (remove arrays, add arena)
- Modify: `engine_juce/src/ProjectEngine.cpp` (use new build/process flow)

**Forbidden Files**: Individual processor .hpp/.cpp files (P1-P6 territory)

**Canonical Names**: `DeviceChainOrchestrator::processChain`, `buildProcessorChain`, `ProcessorArena`

**Acceptance Criteria**:
- Full project compiles
- All existing tests pass with byte-identical output
- 9 parallel runtime arrays removed from `TrackPlaybackSnapshot`
- No `new`/`delete` in audio path

**Parallel-Safe**: No — must run after P1-P6 complete

---

## Package Dependency Graph

```
P0 (infrastructure)
 │
 ├─► P1 (TrackGain) ─┐
 ├─► P2 (synths) ───┤
 ├─► P3 (percussion) ┤
 ├─► P4 (dynamics) ─┤    all parallel after P0
 ├─► P5 (time-based) ┤
 └─► P6 (frequency) ─┘
                       │
                       ▼
                    P7 (integration — last)
```

## Worker Instructions (for all packages)

Implementation agents must:
- Obey canonical names from `02-canonical-vocabulary.md`
- Obey API signatures from `03-api-contracts.md`
- Stay within assigned files from `05-file-ownership.md`
- Not invent public APIs, rename concepts, or redesign architecture
- Not touch files owned by another work package
- Stop and report if any contract item is missing or ambiguous
- Ensure zero allocations, zero locks, zero I/O on the audio thread
- Preserve byte-identical output — use the existing DSP functions unchanged (e.g., `processFilterStereoBlock` is still called internally; only the wrapper changes)