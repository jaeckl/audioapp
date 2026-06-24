# Test Contract: Random Generator Modulator

## Engine Tests (C++)

File: `engine_juce/tests/RandomGeneratorModulatorTest.cpp`

### Test Case 1: Default Parameters
- Create `RandomGeneratorModulatorType`
- Call `createDefault()` → verify `rate == 0.5f`, `smoothing == 0.0f`, `retrigger == 1`, `polarity == 0`

### Test Case 2: setParameter Validation
- Call `setParameter(params, "rate", 0.8f)` → verify `rate == 0.8f`
- Call `setParameter(params, "rate", 2.0f)` → verify clamped to `1.0f`
- Call `setParameter(params, "smoothing", 0.5f)` → verify `smoothing == 0.5f`
- Call `setParameter(params, "retrigger", 2.0f)` → verify `retrigger == 2`
- Call `setParameter(params, "polarity", 1.0f)` → verify `polarity == 1`
- Call `setParameter(params, "unknown_param", 0.5f)` → verify returns `false`

### Test Case 3: Serialization Round-Trip
- Create params with non-default values
- Call `paramsToVar()` → verify JSON shape: `{"rate": 0.8, "smoothing": 0.3, "retrigger": 1, "polarity": 0, "type": "random_generator"}`
- Call `varToParams()` on the produced var → verify all fields match original

### Test Case 4: ModulationGraph Registration
- Create `ModulationGraph` → verify `modulatorTypes().size() == 3`
- Verify last type's `typeId()` returns `"random_generator"`

### Test Case 5: ModulationGraph createLfo
- Call `createLfo(2)` → verify returns an id > 0
- Verify `lfos().size() == 1` and `lfos()[0].typeIndex == 2`

### Test Case 6: ModulationGraph updateLfoParam
- Create a random generator lfo
- Call `updateLfoParam(id, "rate", 0.9f)` → verify success
- Verify params read back correctly

### Test Case 7: ModulationGraph JSON Round-Trip
- Create a graph with various modulators including random generator
- Call `recordsToVar()` → verify JSON includes `"type": "random_generator"` record
- Clear and call `recordsFromVar()` → verify all records restored including random generator

### Test Case 8: RandomGeneratorModulator::evaluate() Output Range
- Create a RandomGeneratorModulator with default params
- Call `evaluate()` multiple times with different playhead positions
- Verify all outputs are in [-1, 1] range (bipolar) or [0, 1] (unipolar)

### Test Case 9: RandomGeneratorModulator::evaluate() Polarity
- Create with `polarity = 0` (bipolar) → verify values in [-1, 1]
- Create with `polarity = 1` (unipolar) → verify values in [0, 1]

### Test Case 10: Smoothing Produces Different Results
- Create one modulator with `smoothing = 0` and another with `smoothing = 1`
- At the same evaluation point just after a step boundary, verify the smoothed version has a different (interpolated) value

## Flutter Tests (Dart)

File: `app_flutter/test/features/modulation/random_generator_test.dart`

### Test 1: Type Constants
- Verify `ModulatorTypes.randomGenerator == 2`
- Verify `ModulatorTypes.labelFor(2) == 'RND'`

### Test 2: LfoSnapshot JSON Parsing (Random Generator)
- Parse a JSON string with `id: 1, type: "random_generator", rate: 0.7, smoothing: 0.4, retrigger: 0, polarity: 1`
- Verify all fields match
- Verify `modulatorType == 2`

### Test 3: LfoSnapshot applyParamUpdate (Random Generator)
- Create a snapshot with `modulatorType = 2`
- Call `applyParamUpdate('rate', 0.9)` → verify `rate == 0.9`
- Call `applyParamUpdate('smoothing', 0.5)` → verify `smoothing == 0.5`
- Call `applyParamUpdate('retrigger', 2)` → verify `retrigger == 2`
- Call `applyParamUpdate('polarity', 1)` → verify `polarity == 1`

### Test 4: LfoSnapshot copyWith (Random Generator)
- Create a snapshot, call `copyWith(smoothing: 0.8)` → verify `smoothing == 0.8`
- Verify other fields unchanged

### Test 5: ModulatorMath.randomGeneratorPreview Output
- Call with known params
- Verify output list length matches `sampleCount`
- Verify each value is in [-1, 1]

### Test 6: Properties Panel Shows Random Generator Layout (Widget Test)
- Render `ModulatorPropertiesPanel` with a random generator snapshot
- Verify rate knob, smoothing knob, retrigger bar, and polarity toggle are present