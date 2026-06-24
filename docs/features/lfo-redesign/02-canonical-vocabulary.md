# Canonical Vocabulary: LFO Modulator Redesign

| Concept | Canonical name | Type/file | Notes |
|---------|---------------|-----------|-------|
| Morph amount (continuous waveform blend) | `morph` | `float` in `LfoParams`; `double` in `LfoSnapshot`; JSON key `"morph"` | Range [0, 1], 0=sine, 0.25=tri boundary, 0.5=saw, 0.75=square, 1.0=ramp |
| Spread amount (pulse-width / skew) | `spread` | `float` in `LfoParams`; `double` in `LfoSnapshot`; JSON key `"spread"` | Range [0, 1], 0.5=symmetric, <0.5 skews down, >0.5 skews up |
| Digital/analog toggle | `analogMode` | `int` in `LfoParams`/`LfoSnapshot`; JSON key `"analogMode"` | 0=digital (adjustable morph/spread), 1=analog (fixed values) |
| Waveform integer | `waveform` | `int` in `LfoParams`; JSON key `"waveform"` | Unchanged, kept for backward compat; no longer exposed in UI |
| Preview evaluation | `lfoWaveMorph` | `static` function in `ModulatorMath` | Takes `(waveform, morph, spread, phase) -> double` |
| LFO preview painter | `LfoPreviewPainter` | `CustomPainter` class in new file | Static display, no playhead dot |
| Preview widget | `LfoPreviewWidget` | `StatelessWidget` in new file | Wraps `LfoPreviewPainter` with DG/AN toggle |
| Warp knob label | `morph` | Knob short label in panel | "Wp" in short form, "Warp" in full |
| Spread knob label | `spread` | Knob short label in panel | "Sp" in short form, "Spread" in full |
| Polarity values | `polarity` | `int` in `LfoParams`/`LfoSnapshot`; JSON key `"polarity"` | 0=bipolar(±), 1=unipolar-pos(+); value 2 kept for backward compat but hidden from UI |

## Forbidden names

| Forbidden | Instead use |
|-----------|-------------|
| `warp` | `morph` |
| `pulseWidth`, `pwm`, `skew`, `symmetry` | `spread` |
| `waveBlend`, `waveformBlend`, `blend` | `morph` |
| `offset`, `shift` | `phase` (unchanged) |