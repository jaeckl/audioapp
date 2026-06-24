# Test Contract: LFO Modulator Redesign

## Test levels

| Level | Tests | Owner WP | Parallel-safe |
|-------|-------|----------|---------------|
| C++ unit | Engine serialization with new fields | WP1 | YES |
| Dart unit | LfoSnapshot parsing of morph/spread | WP2 | YES (after WP1) |
| Dart unit | lfoWaveMorph evaluation correctness | WP3 | YES (after WP2) |
| Dart widget | LFO properties panel layout | WP4 | NO (sequential) |

## Tests that must still pass (no regressions)

All existing tests in these files must pass unchanged:
- `app_flutter/test/lfo_bridge_test.dart`
- `app_flutter/test/lfo_snapshot_parsing_test.dart`
- `app_flutter/test/modulator_math_test.dart`
- Any engine tests (`audioapp_juce_tests`)

## WP1 — C++ engine tests

New tests in existing engine test suite:

| Test | Assertions |
|------|------------|
| `LfoParams morph/spread defaults` | morph=0.0, spread=0.5, analogMode=0 |
| `LfoParams morph/spread serialization` | `paramsToVar`→`varToParams` round-trip preserves all 3 fields |
| `LfoParams morph/spread backward compat` | JSON without morph/spread loads defaults |
| `LfoParams setParameter morph clamp` | morph clamped to [0,1] |
| `LfoParams setParameter spread clamp` | spread clamped to [0,1] |
| `LfoParams setParameter analogMode clamp` | analogMode clamped to [0,1] |

## WP2 — Dart model tests

Additions to `lfo_snapshot_parsing_test.dart`:

| Test | Assertions |
|------|------------|
| `parses morph and spread from LFO JSON` | morph=0.75, spread=0.3 |
| `defaults morph to 0.0 when missing` | morph==0.0 |
| `defaults spread to 0.5 when missing` | spread==0.5 |
| `copyWith updates morph` | new.morph == 0.5, unchanged fields preserved |
| `copyWith updates spread` | new.spread == 0.25, unchanged fields preserved |

Additions to `lfo_bridge_test.dart`:

| Test | Assertions |
|------|------------|
| `updateLfoParam morph` | mock returns snapshot with morph=0.5 |
| `updateLfoParam spread` | mock returns snapshot with spread=0.3 |

## WP3 — Math + preview tests

Additions to `modulator_math_test.dart`:

| Test | Assertions |
|------|------------|
| `lfoWaveMorph at morph=0 matches pure sine` | All points match `lfoWave(0, p)` |
| `lfoWaveMorph at morph=1 matches pure ramp` | All points match `lfoWave(4, p)` |
| `lfoWaveMorph at morph=0.25 is sine→tri blend` | Values between pure sin and pure tri |
| `lfoWaveMorph at morph=0.5 is tri→saw blend` | Values between pure tri and pure saw |
| `lfoWaveMorph at morph=0.75 is saw→square blend` | Values between pure saw and pure square |
| `lfoWaveMorph spread=0.5 same as no spread` | Equals morph-only evaluation |
| `lfoWaveMorph spread extreme still in [-1,1]` | spread=0 and spread=1 produce output in [-1,1] |
| `lfoWaveMorph output range` | All values in [-1, 1] for all combinations of morph [0,1], spread [0,1], phase [0,1] |
| `curvePoints uses morph/spread when non-default` | mod with morph=0.5 produces different curve from morph=0 |

New tests for preview painter (in `lfo_properties_panel_test.dart` or dedicated file):

| Test | Assertions |
|------|------------|
| `LfoPreviewPainter paints bipolar wave` | Center line visible, fills from center |
| `LfoPreviewPainter paints unipolar wave` | No center line, fills from bottom |
| `LfoPreviewPainter responds to morph changes` | Different morph values → different paint output |
| `LfoPreviewWidget DG/AN toggle` | Tapping calls onChanged('analogMode', 1.0) |

## WP4 — Panel widget tests

New tests in `lfo_properties_panel_test.dart`:

| Test | Assertions |
|------|------------|
| `LFO panel renders header` | Text "LFO N" visible |
| `LFO panel renders preview` | LfoPreviewWidget in tree |
| `LFO panel renders retrigger chips` | Free/Sync/On note visible |
| `LFO panel renders polarity chips` | ± and + visible, − absent |
| `LFO panel renders 4 knobs` | Rate, Phase, Warp, Spread labels |
| `LFO panel DG/AN toggle` | Visible at top-right of preview |
| `LFO panel analogMode hides morph/spread handles` | (preview is static, so no-op; just verify no error) |
| `Envelope panel unchanged` | Same test data → same layout as before |