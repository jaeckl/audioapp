# Vertical Work Packages

## Package P1: Automation Path Debug Trace
**Behavior**: Add temporary printf/trace logging at key automation points to verify `localParamId`, envelope values, and final `filterCutoff`.
**Files**: `AutomationPlayback.cpp`, `ProjectEngine.cpp`
**Forbidden**: Changing logic of param mappings or routing
**Canonical names used**: `localParamId`, `filterCutoff`, `SubtractiveParam::FilterCutoff`
**Dependencies**: None (parallel-safe)
**Acceptance**: On a debug build, log output shows:
- `paramIdFromString("filterCutoff", SubtractiveSynth) → 0`
- `applyAutomationValue(SUBTRACTIVE_PARAM::FILTER_CUTOFF, value=0.x) → filterCutoff = 0.x`
**Required tests**: None (debug only)
**Manual verification**: Run with automation clip, inspect stderr
**Parallel**: Yes — safe to run alongside P2

## Package P2: Modulation Path Debug Trace
**Behavior**: Add temporary trace logging in `applyModulation(SubtractiveSynthParams)`, `applySubtractiveModulation`, and the per-frame loop in `mixSubtractiveMidiNotesBlock`.
**Files**: `DeviceChain.cpp`, `SubtractiveSynth.cpp`
**Forbidden**: Changing synth DSP logic or modulation architecture
**Canonical names used**: `filterCutoff`, `modAmount`, `lfoOut`, `amount`
**Dependencies**: None (parallel-safe with P1)
**Acceptance**: Log output shows actual `edge.amount`, `lfoOut`, `modAmount`, and resulting `filterCutoff` per frame
**Required tests**: None (debug only)
**Manual verification**: Set up LFO → filterCutoff modulation, inspect log
**Parallel**: Yes — safe to run alongside P1

## Package P3: Amount Value Validation
**Behavior**: Verify that the `amount` field in `ModulationEdge` (control thread) and `ModulationEdgePlayback` (audio thread) carries the expected non-zero value. Check `assignModulation` in `ModulationGraph.cpp` and `ProjectEngine.cpp`.
**Files**: `modulation/ModulationGraph.cpp`, `ProjectEngine.cpp`
**Forbidden**: Changing modulation graph API
**Dependencies**: P2 (sequential — requires P2 trace to know what amounts arrive)
**Acceptance**: If `amount` is non-zero in the trace, the bug is not in the routing
**Manual verification**: Compare UI slider position with amount arriving at audio thread
**Parallel**: No — depends on P2 output

## Package P4: Flutter Bridge Amount Verification
**Behavior**: Check the Dart-side `assignModulation` bridge call. Verify the amount value is correctly passed from UI knob to engine.
**Files**: `app_flutter/lib/bridge/`, `app_flutter/lib/features/device_strip/`
**Forbidden**: Changing native engine code
**Dependencies**: P3 (sequential — need to know expected amounts)
**Acceptance**: Amount value in bridge call matches what the UI slider shows
**Manual verification**: Print/log bridge calls
**Parallel**: No — depends on P3

## Package P5: FilterCutoff Modulation Test
**Behavior**: Write a C++ unit test that:
1. Creates a `SubtractiveSynthParams` with default `filterCutoff=0.75`
2. Applies modulation with various amounts (±0.1, ±0.5, ±1.0)
3. Verifies `filterCutoff` changes correctly
4. Optionally: renders a few frames and checks the output audio changes
**Files**: `engine_juce/tests/filter_automation_modulation_test.cpp`
**Forbidden**: Changing production code
**Dependencies**: P1, P2 (sequential — test design informed by trace output)
**Acceptance**: Test passes with expected filterCutoff values
**Manual verification**: Run `g++ <flags> test.cpp -o /tmp/test && /tmp/test`
**Parallel**: No — depends on understanding from earlier packages