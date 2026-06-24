# Vertical Work Packages: Random Generator Modulator

## Package Order Overview

```
WP1 (Engine) ──→ WP2 (Flutter/Bridge) ──→ WP3 (Tests)
```

All three packages are **sequential** (WP2 depends on WP1 being mergeable, WP3 depends on WP1+WP2 being complete). There is no parallelization opportunity here because the Flutter side reads engine contract shapes and the tests exercise the full stack.

---

## WP1: Engine Implementation (C++)

**User-Visible Behavior**: Engine can create a Random Generator modulator, process its parameters, serialize/deserialize it, and evaluate it on the audio thread.

**Assigned Files**:
- Create: `engine_juce/include/audioapp/modulation/RandomGeneratorModulator.hpp`
- Create: `engine_juce/src/modulation/RandomGeneratorModulator.cpp`
- Create: `engine_juce/include/audioapp/modulation/RandomGeneratorModulatorType.hpp`
- Modify: `engine_juce/include/audioapp/modulation/ModulatorParams.hpp`
- Modify: `engine_juce/include/audioapp/ModulationTypes.hpp`
- Modify: `engine_juce/src/modulation/ModulationGraph.cpp`

**Forbidden Files**:
- Any file under `app_flutter/`
- Any file under `native_bridge/`
- Any engine files not in the allowed/modify list above

**Canonical Names Used**: See `02-canonical-vocabulary.md`

**API/Data Contracts Used**: See `03-api-contracts.md`, `04-data-contracts.md`

**Acceptance Criteria**:
1. `RandomGeneratorModulatorType` returns correct `typeId()`, `modulatorTypeValue()`, and `createDefault()`
2. `setParameter()` correctly updates `rate`, `smoothing`, `retrigger`, `polarity` with proper clamping
3. `paramsToVar()` / `varToParams()` round-trips correctly
4. `createModulator()` creates a `RandomGeneratorModulator` with correct initial state
5. `ModulationGraph` constructor registers the new type (push_back)
6. `createLfo(2)` creates a Random Generator modulator with default params
7. `updateLfoParam()` dispatches to `RandomGeneratorModulatorType::setParameter()`
8. `recordsToVar()` / `recordsFromVar()` round-trip correctly for random generator records
9. `evaluate()` produces stepped random values; smoothing interpolates between steps
10. Evaluation respects retrigger mode (Free/Sync/OnNote) and polarity

**Required Tests**:
- C++ test: `RandomGeneratorModulatorType` serialization round-trip
- C++ test: `RandomGeneratorModulator::evaluate()` produces non-zero output, respects polarity
- C++ test: `ModulationGraph` can create/update/remove random generator modulators
- C++ test: JSON round-trip via `recordsToVar` / `recordsFromVar`

**Manual Verification Steps**:
- Build engine with `cmake --build build/engine-msvc --target audioapp_juce_tests`
- Run tests: `.\build\engine-msvc\Debug\audioapp_juce_tests.exe RandomGenerator`

**Dependencies**: None

**Integration Risk**: Low — follows identical pattern to LFO/Envelope

**Parallel-Safe**: No (sequential — must complete before WP2)

---

## WP2: Flutter UI Implementation

**User-Visible Behavior**: User can add a Random Generator modulator from the bottom sheet, see its tile in the grid, open its properties panel, and adjust rate/smoothing/retrigger/polarity.

**Assigned Files**:
- Modify: `app_flutter/lib/core/models/project_snapshot.dart`
- Modify: `app_flutter/lib/features/modulation/modulator_types.dart`
- Modify: `app_flutter/lib/features/modulation/modulator_math.dart`
- Modify: `app_flutter/lib/features/modulation/modulator_properties_panel.dart`
- Modify: `app_flutter/lib/features/device_strip/modulation_grid.dart`

**Forbidden Files**:
- Any file under `engine_juce/`
- Any file under `native_bridge/`

**Canonical Names Used**: `randomGenerator`, `RND`, `smoothing`

**API/Data Contracts Used**:
- `ModulatorTypes.randomGenerator = 2`
- `LfoSnapshot` gains `smoothing` field
- `applyParamUpdate()` handles `rate`, `smoothing`, `retrigger`, `polarity` for type 2

**Acceptance Criteria**:
1. `ModulatorTypes.randomGenerator == 2` and `labelFor(2)` returns `"RND"`
2. Bottom sheet in `modulation_grid.dart` shows "Random" entry
3. Creating a Random Generator via bridge works (passes `modulatorType: 2`)
4. `LfoSnapshot` parses `smoothing` from JSON (default 0.0)
5. `applyParamUpdate()` handles all 4 random generator params
6. `copyWith()` includes `smoothing`
7. `ModulatorMath.randomGeneratorPreview()` returns a plausible stepped/smoothed waveform
8. Properties panel shows `_randomGeneratorLayout()` when `modulatorType == 2`
9. Properties panel has: preview area, rate knob, smoothing knob, retrigger bar, polarity toggle
10. Changing rate/smoothing calls `updateLfoParam` bridge method

**Required Tests**:
- Dart test: `LfoSnapshot` parses random generator JSON correctly
- Dart test: `ModulatorMath.randomGeneratorPreview()` returns correct length array
- Widget test: Properties panel shows correct controls for random generator type

**Manual Verification Steps**:
- Run `cd app_flutter && flutter test` — all tests pass
- Run `cd app_flutter && flutter analyze` — no new errors

**Dependencies**: WP1 (engine must support the new type at bridge level)

**Integration Risk**: Medium — the bridge already uses `createLfo` and `updateLfoParam` generically, so no bridge changes needed. Risk is in correct param mapping between Dart and C++.

**Parallel-Safe**: No (sequential after WP1)

---

## WP3: Tests

**User-Visible Behavior**: None (testing only)

**Assigned Files**:
- Create: `engine_juce/tests/RandomGeneratorModulatorTest.cpp`
- Create: `app_flutter/test/features/modulation/random_generator_test.dart`

**Forbidden Files**:
- Any production source files (no changes to implementation)

**Acceptance Criteria**:
1. Engine test compiles and links against `audioapp_engine_tests` target
2. Engine test covers: construction, default params, setParameter, paramsToVar/varToParams, evaluate output range, polarity, retrigger modes
3. Dart test covers: JSON parsing, `applyParamUpdate()`, preview math, copyWith
4. All tests pass

**Required Tests**: Same as AC above

**Dependencies**: WP1 and WP2 must be complete and merged

**Integration Risk**: Low (tests only)

**Parallel-Safe**: No (must be last)