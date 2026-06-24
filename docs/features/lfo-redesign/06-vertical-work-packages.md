# Vertical Work Packages: LFO Modulator Redesign

## WP1 — C++ engine parameters (morph/spread/analogMode)

**Behavior:** Engineer adds `morph`, `spread`, and `analogMode` fields to `LfoParams`, with `setParameter`, `paramsToVar`, and `varToParams` support in `LfoModulatorType`.

**Assigned files:**
- `engine_juce/include/audioapp/modulation/ModulatorParams.hpp`
- `engine_juce/include/audioapp/modulation/LfoModulatorType.hpp`

**Forbidden files:**
- `LfoModulator.hpp` / `.cpp`
- `ModulationTypes.hpp`
- Any Dart files

**Canonical names used:**
- `morph` (float, default 0.0, clamp [0,1])
- `spread` (float, default 0.5, clamp [0,1])
- `analogMode` (int, default 0, clamp [0,1])

**API/data contracts:** See `04-data-contracts.md` for JSON keys and struct layout.

**Dependencies:** None.

**Parallel-safe:** YES — independent of all Dart work.

**Acceptance criteria:**
1. `LfoParams` compiles with the 3 new fields at correct defaults
2. `setParameter("morph", 0.5)` sets `p.morph = 0.5`
3. `paramsToVar` output includes `"morph"`, `"spread"`, `"analogMode"` keys with correct types
4. `varToParams` reads all 3 keys; missing keys fall back to defaults
5. `setParameter` clamps morph to [0,1], spread to [0,1], analogMode to [0,1]
6. All existing unit tests still pass

**Required tests:**
- Test morph/spread serialization round-trip
- Test analogMode serialization round-trip
- Test backward compat (missing keys → defaults)
- Test clamp behavior

**Manual verification:**
- `cmake -S engine_juce -B build/engine-msvc && cmake --build build/engine-msvc`
- Existing `audioapp_juce_tests` passes

---

## WP2 — Dart LfoSnapshot model (morph/spread fields)

**Behavior:** Adds `morph`, `spread` fields to `LfoSnapshot` with `fromMap` parsing, copyWith, and constructor defaults.

**Assigned files:**
- `app_flutter/lib/bridge/project_snapshot.dart`
- `app_flutter/test/lfo_snapshot_parsing_test.dart`
- `app_flutter/test/lfo_bridge_test.dart`

**Forbidden files:**
- Any C++ files
- Any UI widget files

**Canonical names used:**
- `morph` (double, default 0.0, parsed from `"morph"`)
- `spread` (double, default 0.5, parsed from `"spread"`)

**Dependencies:** WP1 must be merged first (to validate JSON keys match).

**Parallel-safe:** YES after WP1 stubs exist (contract defines JSON keys precisely).

**Acceptance criteria:**
1. `LfoSnapshot.fromMap` with `"morph": 0.75, "spread": 0.3` sets those fields
2. `LfoSnapshot.fromMap` without those keys uses defaults (0.0, 0.5)
3. `copyWith(morph: 0.5)` returns new instance with updated morph
4. All existing test assertions continue to pass
5. Bridge test mock handler recognizes `"morph"` and `"spread"` param updates

**Required tests:**
- Test morph/spread round-trip fromMap
- Test missing key defaults
- Test copyWith propagation
- Test bridge param update for morph, spread, analogMode

---

## WP3 — Dart LFO math + preview painter

**Behavior:** Adds `lfoWaveMorph()` to `ModulatorMath` and creates `LfoPreviewPainter` + `LfoPreviewWidget` for the static waveform display.

**Assigned files:**
- `app_flutter/lib/features/device_strip/modulator_math.dart` (add `lfoWaveMorph`)
- `app_flutter/lib/features/device_strip/lfo_preview_painter.dart` (NEW)
- `app_flutter/test/modulator_math_test.dart`

**Forbidden files:**
- `modulator_properties_panel.dart` (WP4 owns integration)
- Any engine files

**Canonical names used:**
- `lfoWaveMorph(int waveform, double morph, double spread, double phase) -> double`
- `LfoPreviewPainter` class
- `LfoPreviewWidget` class

**Dependencies:** WP2 must be merged (LfoSnapshot has morph/spread fields).

**Parallel-safe:** YES after WP2 model lands.

**Acceptance criteria:**
1. `lfoWaveMorph(wf=0, morph=0.0, spread=0.5, phase)` matches `lfoWave(wf=0, phase)` exactly (pure sine)
2. `lfoWaveMorph(wf=0, morph=0.25, spread=0.5, phase)` blends sine→tri at midpoint
3. `lfoWaveMorph(wf=0, morph=1.0, spread=0.5, phase)` matches `lfoWave(wf=4, phase)` exactly (pure ramp)
4. Spread=0.5 yields symmetric waveform (same as spread-less for all base waves)
5. `lfoWaveMorph` output stays in [-1, 1] range
6. `LfoPreviewPainter` renders one cycle with correct polarity visualization
7. `LfoPreviewWidget` shows DG/AN toggle in top-right corner
8. `LfoPreviewWidget` with analogMode=1 hides morph/spread handles (no-op since preview is static)
9. `curvePoints` for LFO type uses `lfoWaveMorph` when morph!=0 or spread!=0.5

**Required tests:**
- morph=0 → pure sine output
- morph=1.0 → pure ramp output (last waveform)
- morph=0.25, 0.5, 0.75 → correct boundaries
- spread=0.5 → symmetric (same as identity)
- spread=0.0, spread=1.0 → extreme skew values (shape changes, still in [-1,1])
- All points in [-1,1] range
- Preview painter renders without error at both polarity values

---

## WP4 — LFO properties panel UI

**Behavior:** Replaces the scrollable `_lfoLayout` with the new layout: header → Expanded LfoPreviewWidget → retrigger bar → polarity chips → knob row (Rate, Phase, Warp, Spread). Adds DG/AN toggle.

**Assigned files:**
- `app_flutter/lib/features/device_strip/modulator_properties_panel.dart`
- `app_flutter/lib/features/device_strip/modulator_rate_codec.dart` (add `formatMorph`, `formatSpread`)
- `app_flutter/test/lfo_properties_panel_test.dart` (NEW)

**Forbidden files:**
- `modulator_math.dart` (read-only reference)
- Any engine files
- `project_snapshot.dart`

**Canonical names used:**
- `morph` → knob labeled "Wp" / "Warp"
- `spread` → knob labeled "Sp" / "Spread"
- `polarity` → 2-chip row: `±`, `+`
- `analogMode` → DG/AN toggle top-right of preview

**Dependencies:** WP2 (model) + WP3 (preview widget) must be merged.

**Parallel-safe:** NO — must be sequential after WP2 and WP3.

**Acceptance criteria:**
1. LFO panel uses same layout pattern as envelope (header → Expanded preview → mode bar → knob row)
2. Preview shows `LfoPreviewWidget` in an `Expanded` widget
3. DG/AN toggle appears top-right of preview (matches envelope pattern)
4. Retrigger chips are a compact row: DG/AN toggle + "Free", "Sync", "On note"
5. Polarity row shows exactly 2 chips: `±` and `+` (no `−`)
6. Knobs row shows 4 knobs: Rate, Phase, Warp, Spread
7. Morph knob has label "Wp", display formatted by `ModulatorRateCodec.formatMorph`
8. Spread knob has label "Sp", display formatted by `ModulatorRateCodec.formatSpread`
9. AnalogMode=1: morph/spread knobs are visible but show fixed values (morph=0, spread=0.5)
10. No animated playhead dot in preview
11. All existing envelope panel behavior unchanged
12. Layout fits on a mobile screen without scrolling for typical phone sizes

**Required tests:**
- Widget renders all sections: header, preview, retrigger bar, polarity chips, knob row
- Tapping DG/AN toggles `analogMode` via onUpdate
- Tapping polarity chips calls onUpdate with correct value
- Morph/spread knobs call onUpdate with correct param name
- Envelope layout unaffected (regression test)