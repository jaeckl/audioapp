# File Ownership: LFO Modulator Redesign

| File/path | Owner WP | Allowed changes | Forbidden changes |
|-----------|----------|-----------------|-------------------|
| `engine_juce/include/audioapp/modulation/ModulatorParams.hpp` | WP1 | Add `morph`, `spread`, `analogMode` fields to `LfoParams` | Remove or rename existing fields; change envelope params |
| `engine_juce/include/audioapp/modulation/LfoModulatorType.hpp` | WP1 | Add `"morph"`, `"spread"`, `"analogMode"` to `setParameter`, `paramsToVar`, `varToParams` | Change `waveform` handling; change envelope code path |
| `engine_juce/src/modulation/LfoModulator.cpp` | — | No changes | No changes to audio-thread evaluation |
| `engine_juce/include/audioapp/modulation/LfoModulator.hpp` | — | No changes | No changes to audio-thread evaluation |
| `engine_juce/include/audioapp/ModulationTypes.hpp` | — | No changes | — |
| `app_flutter/lib/bridge/project_snapshot.dart` | WP2 | Add `morph`, `spread` to `LfoSnapshot` ctor, `fromMap`, `copyWith` | Remove existing fields; change polarity parsing defaults |
| `app_flutter/lib/features/device_strip/modulator_math.dart` | WP3 | Add `lfoWaveMorph()` function; update `curvePoints` to use morph/spread when `type=='lfo'` | Change envelope evaluation; change `phaseDot` |
| `app_flutter/lib/features/device_strip/modulator_properties_panel.dart` | WP4 | Replace `_lfoLayout` with new design; add morph/spread knobs; add DG/AN toggle; add preview widget reference | Modify `_envelopeLayout`; change envelope knobs; change envelope header |
| `app_flutter/lib/features/device_strip/modulator_rate_codec.dart` | WP4 | Add `formatMorph`, `formatSpread` | Remove existing formatting |
| `app_flutter/lib/features/device_strip/modulator_types.dart` | — | No changes | — |
| `app_flutter/lib/features/device_strip/envelope_preview_painter.dart` | — | No changes | Template/pattern reference only |
| `app_flutter/lib/features/device_strip/modulation_grid.dart` | — | No changes | — |
| `app_flutter/lib/features/device_strip/lfo_preview_painter.dart` (NEW) | WP3 | Create `LfoPreviewPainter` + `LfoPreviewWidget` | Must not contain animated playhead dot |
| `app_flutter/test/lfo_snapshot_parsing_test.dart` | WP2 | Add tests for morph/spread parsing | — |
| `app_flutter/test/modulator_math_test.dart` | WP3 | Add tests for `lfoWaveMorph` | — |
| `app_flutter/test/lfo_properties_panel_test.dart` (NEW) | WP4 | Add widget tests for new LFO panel layout | — |
| `app_flutter/test/lfo_bridge_test.dart` | WP1 | Add test for morph/spread param update | — |

## Shared files requiring care

- `project_snapshot.dart`: WP1 engine changes → WP2 Dart model → WP3/4 UI consumers. WP2 is the shared contract point and must be completed before WP3/WP4.
- `modulator_math.dart`: WP3 adds `lfoWaveMorph` which is used by WP4 preview + curvePoints. WP3 must complete before WP4.
- `modulator_properties_panel.dart`: WP4 owns the UI — but depends on WP2 (model fields) and WP3 (math + preview painter).