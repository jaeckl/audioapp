# Data Contracts: LFO Modulator Redesign

## C++ struct (unchanged fields omitted, additions only)

```cpp
struct LfoParams {
    // ... existing fields unchanged ...
    float morph = 0.0f;       // [0,1]: 0=sine, 0.25=tri, 0.5=saw, 0.75=sq, 1.0=ramp
    float spread = 0.5f;      // [0,1]: 0.5=symmetric, <0.5 skew, >0.5 skew
    int analogMode = 0;       // 0=digital, 1=analog (fixed morph=0, spread=0.5)
};
```

## JSON serialization (engine → Flutter)

```json
{
  "id": 5,
  "type": "lfo",
  "waveform": 0,
  "rate": 0.6,
  "syncDivision": 3,
  "retrigger": 0,
  "phase": 0.25,
  "polarity": 0,
  "morph": 0.32,
  "spread": 0.5,
  "analogMode": 0,
  "attack": 0.1,
  "decay": 0.25,
  "sustain": 0.7,
  "release": 0.35
}
```

**Backward compat:** Old JSON without `morph`/`spread`/`analogMode` loads with defaults (0.0, 0.5, 0).

## Dart LfoSnapshot additions

```dart
class LfoSnapshot {
  const LfoSnapshot({
    // ... existing fields ...
    this.morph = 0.0,
    this.spread = 0.5,
    this.analogMode = 0,
  });

  final double morph;
  final double spread;
  final int analogMode;

  factory LfoSnapshot.fromMap(Map<dynamic, dynamic> map) {
    // ... existing parsing for lfo branch ...
    morph: (map['morph'] as num?)?.toDouble() ?? 0.0,
    spread: (map['spread'] as num?)?.toDouble() ?? 0.5,
    analogMode: (map['analogMode'] as num?)?.toInt() ?? 0,
  }

  LfoSnapshot copyWith({
    // ... existing fields ...
    double? morph,
    double? spread,
    int? analogMode,
  });
}
```

## AnalogMode behavior

| analogMode | morph | spread | UI morph handle | UI spread handle |
|------------|-------|--------|-----------------|------------------|
| 0 (DG) | user-set | user-set | visible, active | visible, active |
| 1 (AN) | fixed 0.0 | fixed 0.5 | hidden | hidden |

When switching between DG and AN, the engine updates morph/spread to the fixed defaults (0.0 / 0.5). Switching back to DG restores the last user-set values (held in UI state).

## Polarity (UI only)

| polarity | UI label | Preview behavior |
|----------|----------|-----------------|
| 0 | `±` | Center line + fill from center (bipolar) |
| 1 | `+` | No center line, fill from bottom (unipolar-pos) |
| 2 (engine only, hidden) | — | — |

The engine continues to accept and store polarity=2, but the UI no longer offers it.

## Morph evaluation equation

```python
# Pseudo-code for morphed waveform at phase p [0..1)
def lfo_wave_morph(waveform: int, morph: float, spread: float, phase: float) -> float:
    p = phase - floor(phase)

    # Apply spread FIRST (warp the phase)
    p = apply_spread(p, spread)

    # Map morph [0,1] to segment [0..4]
    seg = morph * 4.0  # 0..4
    idx = floor(seg)    # 0,1,2,3
    frac = seg - idx    # 0..1 blend factor

    a = evaluate_pure(wave_segments[idx], p)
    b = evaluate_pure(wave_segments[idx + 1], p)
    return lerp(a, b, frac)
```

Where `evaluate_pure` is the existing 5-waveform evaluation and `wave_segments` is the ordered list: [sine, tri, saw, square, ramp].

## Spread (phase warping)

```
apply_spread(phase, spread):
    # spread 0.5 = identity (no change)
    # spread < 0.5: compress then expand (wave leans left)
    # spread > 0.5: expand then compress (wave leans right)
    if spread < 0.5:
        t = spread * 2  # [0, 1)
        return phase ^ (1 - t/2)  # power curve
    else:
        t = (spread - 0.5) * 2  # [0, 1)
        return phase ^ (1 + t * 2)  # inverse power curve
```

Actually — the spread function needs more thought. The cleanest approach:

For **square wave**: spread=0.5 gives 50% duty. spread=0.25 gives 25% duty. spread=0.75 gives 75% duty.

For **saw/tri**: spread shifts the peak/zero-crossing point.

For **sine**: spread adds through-zero phase distortion.

Implementation in Dart `ModulatorMath.lfoWaveMorph`:

```dart
static double lfoWaveMorph(
  int waveform, double morph, double spread, double phase,
) {
  // 1. Wrap phase
  phase = phase - phase.floorToDouble();

  // 2. Apply spread via piecewise remap
  if (spread != 0.5) {
    if (spread < 0.5) {
      // Compress first portion, expand second
      final split = spread * 2.0; // [0, 1)
      if (phase < split) {
        phase = phase / split * 0.5;
      } else {
        phase = 0.5 + (phase - split) / (1.0 - split) * 0.5;
      }
    } else {
      // Expand first portion, compress second
      final split = (spread - 0.5) * 2.0; // [0, 1)
      if (phase < 0.5) {
        phase = phase / 0.5 * split;
      } else {
        phase = split + (phase - 0.5) / 0.5 * (1.0 - split);
      }
    }
  }

  // 3. Determine segment and blend factor
  final seg = morph * 4.0;
  final idx = seg.floor();
  final frac = seg - seg.floor();

  if (idx >= 4) return _evalWf(4, phase); // ramp at exact 1.0

  final a = _evalWf(idx, phase);
  final b = _evalWf(idx + 1, phase);
  return a + (b - a) * frac;
}

static double _evalWf(int wf, double phase) {
  // Same as existing lfoWave but switch-based for clarity
  ...
}
```