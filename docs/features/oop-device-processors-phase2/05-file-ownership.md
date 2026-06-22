# OOP Device Processors Phase 2 — File Ownership

This document defines which files are created, modified, or deleted in Phase 2, and which work package owns each file.

---

## File Ownership Table

| File | Action | Owner Package | Allowed Changes | Forbidden Changes |
|------|--------|--------------|-----------------|-------------------|
| `engine_juce/include/audioapp/devices/processors/DeviceProcessor.hpp` | **Create** | P0 | Abstract base class definition | Adding logic beyond pure virt + default |
| `engine_juce/include/audioapp/devices/processors/AudioBlock.hpp` | **Create** | P0 | AudioBlock struct | Adding methods beyond clear/addFrom/applyGain |
| `engine_juce/include/audioapp/devices/processors/ProcessContext.hpp` | **Create** | P0 | ProcessContext struct | Removing any field needed by processors |
| `engine_juce/include/audioapp/devices/processors/ProcessorArena.hpp` | **Create** | P0 | ProcessorArena class + kMaxProcessorSize | Changing emplace/get/reset contract |
| `engine_juce/include/audioapp/devices/processors/ProcessorArena.cpp` | **Create** | P0 | Static assert for processor sizes | Logic changes |
| `engine_juce/include/audioapp/DeviceChainOrchestrator.hpp` | **Create** | P0 | New orchestrator API | Modifying existing public API |
| `engine_juce/src/DeviceChainOrchestrator.cpp` | **Create** | P0 | Orchestrator loop implementation + buildProcessorChain | Adding device-specific DSP |
| `engine_juce/include/audioapp/DeviceChainScratch.hpp` | **Modify** | P0 | Add `DeviceChainScratchArena` struct and `ringBufferArena` member | Removing existing scratch fields |
| `engine_juce/include/audioapp/DeviceChainProcessor.hpp` | **Modify** (minimal) | P0 | Add `#include "DeviceChainOrchestrator.hpp"` if needed | Changing existing `processDeviceNode` signature |
| `engine_juce/src/DeviceChainProcessor.cpp` | **Modify** | P7 | Replace switch-case with delegating wrapper to new orchestrator | — |
| `engine_juce/src/DeviceChain.cpp` | **Modify** | P7 | Replace `processDeviceNode()` calls with orchestrator loop | Changing `processDeviceChain` public signature initially |
| `engine_juce/include/audioapp/ProjectEngine.hpp` | **Modify** | P7 | Remove runtime arrays from `TrackPlaybackSnapshot`, add `ProcessorArena` | Changing render logic |
| `engine_juce/src/ProjectEngine.cpp` | **Modify** | P7 | Update `mixAtPlayheadBeatStereo` to use new orchestrator | — |
| `engine_juce/CMakeLists.txt` | **Modify** | P0 | Add new .cpp files to build | Changing compile flags |

### Per-processor files (P1-P6)

| File | Action | Owner | Allowed Changes |
|------|--------|-------|-----------------|
| `.../devices/processors/TrackGainProcessor.hpp` | **Modify** | P1 | Change to subclass `DeviceProcessor`, add `process()` override |
| `.../devices/processors/TrackGainProcessor.cpp` | **Modify** | P1 | Rewrite to use `AudioBlock&`, `ProcessContext&`, embedded state |
| `.../devices/processors/OscillatorProcessor.hpp` | **Modify** | P2 | Same pattern — `DeviceProcessor` subclass, `float oscillatorPhase_` member |
| `.../devices/processors/OscillatorProcessor.cpp` | **Modify** | P2 | Rewrite to OOP form |
| `.../devices/processors/SamplerProcessor.hpp` | **Modify** | P2 | `BiquadState samplerFilterStates_[32]` member |
| `.../devices/processors/SamplerProcessor.cpp` | **Modify** | P2 | Rewrite to OOP form |
| `.../devices/processors/SubtractiveSynthProcessor.hpp` | **Modify** | P2 | `SubtractiveSynthRuntime runtime_` member |
| `.../devices/processors/SubtractiveSynthProcessor.cpp` | **Modify** | P2 | Rewrite to OOP form |
| `.../devices/processors/PhaseModSynthProcessor.hpp` | **Modify** | P2 | `PhaseModSynthRuntime runtime_` member |
| `.../devices/processors/PhaseModSynthProcessor.cpp` | **Modify** | P2 | Rewrite to OOP form |
| `.../devices/processors/KickProcessor.hpp` | **Modify** | P3 | `KickGeneratorRuntime runtime_` member |
| `.../devices/processors/KickProcessor.cpp` | **Modify** | P3 | Rewrite to OOP form |
| `.../devices/processors/SnareProcessor.hpp` | **Modify** | P3 | `SnareGeneratorRuntime runtime_` member |
| `.../devices/processors/SnareProcessor.cpp` | **Modify** | P3 | Rewrite |
| `.../devices/processors/ClapProcessor.hpp` | **Modify** | P3 | `ClapGeneratorRuntime runtime_` member |
| `.../devices/processors/ClapProcessor.cpp` | **Modify** | P3 | Rewrite |
| `.../devices/processors/CymbalProcessor.hpp` | **Modify** | P3 | `CymbalGeneratorRuntime runtime_` member |
| `.../devices/processors/CymbalProcessor.cpp` | **Modify** | P3 | Rewrite |
| `.../devices/processors/CrashProcessor.hpp` | **Modify** | P3 | `CrashGeneratorRuntime runtime_` member |
| `.../devices/processors/CrashProcessor.cpp` | **Modify** | P3 | Rewrite |
| `.../devices/processors/GateProcessor.hpp` | **Modify** | P4 | `DynamicsRuntime runtime_` member |
| `.../devices/processors/GateProcessor.cpp` | **Modify** | P4 | Rewrite to OOP form |
| `.../devices/processors/CompressorProcessor.hpp` | **Modify** | P4 | `DynamicsRuntime runtime_` member |
| `.../devices/processors/CompressorProcessor.cpp` | **Modify** | P4 | Rewrite |
| `.../devices/processors/ExpanderProcessor.hpp` | **Modify** | P4 | `DynamicsRuntime runtime_` member |
| `.../devices/processors/ExpanderProcessor.cpp` | **Modify** | P4 | Rewrite |
| `.../devices/processors/LimiterProcessor.hpp` | **Modify** | P4 | `DynamicsRuntime runtime_` member |
| `.../devices/processors/LimiterProcessor.cpp` | **Modify** | P4 | Rewrite |
| `.../devices/processors/DelayProcessor.hpp` | **Modify** | P5 | Buffer pointers + writeIndex members, remove heap alloc |
| `.../devices/processors/DelayProcessor.cpp` | **Modify** | P5 | Rewrite to use `AudioBlock`, `ProcessContext`, ring buffer arena |
| `.../devices/processors/ReverbProcessor.hpp` | **Modify** | P5 | Same as DelayProcessor |
| `.../devices/processors/ReverbProcessor.cpp` | **Modify** | P5 | Rewrite |
| `.../devices/processors/ChorusProcessor.hpp` | **Modify** | P5 | Same |
| `.../devices/processors/ChorusProcessor.cpp` | **Modify** | P5 | Rewrite |
| `.../devices/processors/PhaserProcessor.hpp` | **Modify** | P5 | Buffer pointers + phaser state members |
| `.../devices/processors/PhaserProcessor.cpp` | **Modify** | P5 | Rewrite |
| `.../devices/processors/FilterProcessor.hpp` | **Modify** | P6 | `FilterRuntime runtime_` member |
| `.../devices/processors/FilterProcessor.cpp` | **Modify** | P6 | Rewrite to OOP form |
| `.../devices/processors/FourBandEqProcessor.hpp` | **Modify** | P6 | `FourBandEqRuntime runtime_` member |
| `.../devices/processors/FourBandEqProcessor.cpp` | **Modify** | P6 | Rewrite |
| `.../devices/processors/FrequencyShifterProcessor.hpp` | **Modify** | P6 | `FrequencyShifterRuntime runtime_` member |
| `.../devices/processors/FrequencyShifterProcessor.cpp` | **Modify** | P6 | Rewrite |

---

## Shared Files Requiring Coordination

| File | Accessed By | Risk |
|------|-------------|------|
| `engine_juce/CMakeLists.txt` | P0 only | Low — P0 adds new files; P1-P6 don't touch |
| `engine_juce/src/DeviceChainProcessor.cpp` | P7 only | Low — P7 replaces entire contents |
| `engine_juce/src/DeviceChain.cpp` | P7 only | Low — P7 rewrites orchestrator loop |
| `engine_juce/include/audioapp/ProjectEngine.hpp` | P7 only | Low — remove arrays, add ProcessorArena |
| `engine_juce/include/audioapp/DeviceChain.hpp` | P0, P7 | Low — P0 adds new types, P7 modifies TrackPlaybackSnapshot |

## Strict Rules

1. **P1-P6 subagents may ONLY modify their assigned processor .hpp and .cpp files.** They must NOT modify DeviceChain.cpp, ProjectEngine.hpp, CMakeLists.txt, or DeviceChainProcessor.cpp.
2. **P0 must complete before P1-P6 start.** P0 creates the base class, AudioBlock, ProcessContext, ProcessorArena, DeviceChainOrchestrator (stubs), DeviceChainScratchArena, and updates CMakeLists.txt.
3. **P1-P6 can run in parallel** since each works on separate processor files.
4. **P7 runs last** — it wires the new orchestrator into DeviceChain.cpp, updates ProjectEngine, and removes old parallel arrays.