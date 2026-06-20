# Test Contract

## Existing Tests
No existing C++ tests exercise the automation or modulation paths for `filterCutoff` on the SubtractiveSynth.

## Required Test: P5 — FilterCutoff Modulation Unit Test
File: `engine_juce/tests/filter_automation_modulation_test.cpp`

### Test 1: verifyApplyAutomationValue
```cpp
// Given: SubtractiveSynthParams with default filterCutoff=0.75
// When: applyAutomationValue(params, SubtractiveSynth, FilterCutoff, 0.3f)
// Then: params.filterCutoff == 0.3f
```

### Test 2: verifyModulationAdditive
```cpp
// Given: SubtractiveSynthParams with filterCutoff=0.75, LocalParamID=FilterCutoff, modAmount=+0.2
// When: applySubtractiveModulation(params, +0.2, FilterCutoff)
// Then: params.filterCutoff == 0.95
```

### Test 3: verifyModulationNegative
```cpp
// Given: SubtractiveSynthParams with filterCutoff=0.75, modAmount=-0.5
// When: applySubtractiveModulation(params, -0.5, FilterCutoff)
// Then: params.filterCutoff == 0.25
```

### Test 4: verifyModulationClampBoundary
```cpp
// Given: SubtractiveSynthParams with filterCutoff=0.75, modAmount=+10.0
// When: applySubtractiveModulation(params, +10.0, FilterCutoff)
// Then: params.filterCutoff == 1.0 (clamped)
```

### Test 5: verifyParamIdResolution
```cpp
// Given: DeviceNodeKind::SubtractiveSynth
// When: paramIdFromString("filterCutoff", SubtractiveSynth)
// Then: result == 0 (SubtractiveParam::FilterCutoff)
```

### Test 6: verifyNonMatchingParamId
```cpp
// Given: DeviceNodeKind::SubtractiveSynth
// When: paramIdFromString("gain", SubtractiveSynth)
// Then: result == CommonParam::Gain (Gain is a common param, not SubtractiveParam)
```

### Test 7: verifyAutomationEnvelopeE2E
```cpp
// Given: SubtractiveSynthParams with default filterCutoff=0.75
// Given: AutomationClipPlayback with 2 points (0, 0.0) and (4, 1.0) targeting deviceIndex=0 with localParamId=0
// When: applyDspAutomationAtBeat(params, SubtractiveSynth, 0, beat=2.0, clips, 1)
// Then: params.filterCutoff == 0.5 (midpoint)
// When: applyDspAutomationAtBeat(params, ..., beat=0.0)
// Then: params.filterCutoff == 0.0
// When: applyDspAutomationAtBeat(params, ..., beat=4.0)
// Then: params.filterCutoff == 1.0
```

### Test 8: verifyModulationEdgeE2E
```cpp
// Given: SubtractiveSynthParams with default filterCutoff=0.75
// Given: ModulationEdgePlayback with deviceIndex=0, localParamId=0, lfoId=0, amount=0.5
// Given: LFO buffer with one LFO, lfoValues[0..0] = {1.0} (bipolar max)
// When: applySubtractiveModulation(params, 0.5*1.0, FilterCutoff)
// Then: params.filterCutoff == std::clamp(0.75+0.5, 0, 1) == 1.0
```

## Test Infrastructure
The test file must define `int main()` (as is the pattern in the engine tests). It should link against the static library and compile with appropriate g++ flags.

## Integration Risk
If `normalizedCutoffToHz(0.0)` produces a near-DC frequency, the filter may be essentially closed. This is not a routing bug but an audible behavior issue that may affect test correctness perception.