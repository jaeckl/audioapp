# File Ownership: Random Generator Modulator

## New Files to Create

| File | Owner WP | Responsibility |
|------|----------|---------------|
| `engine_juce/include/audioapp/modulation/RandomGeneratorModulatorType.hpp` | WP1 | Header for type descriptor + inline implementations |
| `engine_juce/src/modulation/RandomGeneratorModulatorType.cpp` | WP1 | Non-inline implementations (only if needed; otherwise keep header-only) |
| `engine_juce/include/audioapp/modulation/RandomGeneratorModulator.hpp` | WP1 | Header for audio-thread modulator |
| `engine_juce/src/modulation/RandomGeneratorModulator.cpp` | WP1 | Audio-thread evaluation implementation |
| `engine_juce/tests/RandomGeneratorModulatorTest.cpp` | WP3 | Unit tests for engine |
| `app_flutter/test/features/modulation/random_generator_test.dart` | WP3 | Unit tests for Flutter |

## Existing Files to Modify

| File | Owner WP | Allowed Changes |
|------|----------|----------------|
| `engine_juce/include/audioapp/modulation/ModulatorParams.hpp` | WP1 | Add `RandomGeneratorParams` struct, update `ModulatorParams` variant |
| `engine_juce/include/audioapp/ModulationTypes.hpp` | WP1 | Add `RandomGenerator = 2` to `ModulatorType` enum |
| `engine_juce/include/audioapp/modulation/ModulationGraph.hpp` | WP1 | No changes needed (already generic) |
| `engine_juce/src/modulation/ModulationGraph.cpp` | WP1 | Add `#include`, add `push_back` in constructor, fix `createLfo` clamp |
| `app_flutter/lib/core/models/project_snapshot.dart` | WP2 | Add `smoothing` field to `LfoSnapshot`, update `applyParamUpdate()`, `copyWith()`, `fromJson()`, `toJson()` |
| `app_flutter/lib/features/modulation/modulator_types.dart` | WP2 | Add `randomGenerator = 2` constant, update `labelFor()` |
| `app_flutter/lib/features/modulation/modulator_math.dart` | WP2 | Add `randomGeneratorPreview()` function |
| `app_flutter/lib/features/modulation/modulator_properties_panel.dart` | WP2 | Add `_randomGeneratorLayout()` method and dispatch |
| `app_flutter/lib/features/device_strip/modulation_grid.dart` | WP2 | Add "Random" entry to `_showAddMenu()` bottom sheet |

## Files with NO Changes Needed

| File | Reason |
|------|--------|
| `native_bridge/src/BridgeHost.cpp` | Already generic — passes `modulatorType` int and forwards `param`/`value` |
| `native_bridge/include/audioapp/bridge/BridgeHost.hpp` | No new bridge methods needed |
| `engine_juce/src/EngineHost_commands.cpp` | Already delegates to `project_->createLfo()` and `project_->updateLfoParam()` |
| `engine_juce/include/audioapp/EngineHost.hpp` | API surface unchanged |

## Shared Files Requiring Care

| File | WP Conflict Risk | Mitigation |
|------|-----------------|------------|
| `ModulatorParams.hpp` | WP1 only | Single owner |
| `project_snapshot.dart` | WP2 only | Single owner |
| `modulator_types.dart` | WP2 only | Single owner |
| `ModulationGraph.cpp` | WP1 only | Single owner |