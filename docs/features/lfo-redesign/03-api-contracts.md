# API Contracts: LFO Modulator Redesign

## C++ LfoModulatorType (no new API surface)

No new methods. The existing `setParameter`, `paramsToVar`, `varToParams` are extended with two more keys.

### `setParameter` additions

| paramId | Type | Clamp | Default |
|---------|------|-------|---------|
| `"morph"` | `float` | `[0, 1]` | `0.0f` |
| `"spread"` | `float` | `[0, 1]` | `0.5f` |
| `"analogMode"` | `int` | `[0, 1]` | `0` |

### `paramsToVar` additions

```json
{
  "morph": 0.0,
  "spread": 0.5,
  "analogMode": 0
}
```

### `varToParams` additions

Reads `"morph"` (default 0.0), `"spread"` (default 0.5), `"analogMode"` (default 0) using existing `readFloat` / `readInt` helpers.

## Dart ModulatorMath

```dart
/// Evaluate morphed/spread waveform at a given phase [0..1).
/// [waveform] is the base int (0=Sine..4=Ramp).
/// [morph] is 0..1 blending between adjacent waveforms.
/// [spread] is 0..1 skew/pulse-width control (0.5 = symmetric).
static double lfoWaveMorph(
  int waveform,
  double morph,
  double spread,
  double phase,
)
```

Returns normalized value in [-1, 1] range (same as existing `lfoWave`).

## Dart ModulatorRateCodec additions

```dart
static String formatMorph(double morph);
static String formatSpread(double spread);
```

## Dart LfoSnapshot field additions

| Field | Type | Default | JSON key |
|-------|------|---------|----------|
| `morph` | `double` | `0.0` | `"morph"` |
| `spread` | `double` | `0.5` | `"spread"` |

These are added to the constructor, `copyWith`, and `fromMap`.

## UI component

```dart
/// Static LFO waveform preview with 2 polarity modes and DG/AN toggle.
class LfoPreviewWidget extends StatelessWidget {
  const LfoPreviewWidget({
    required this.mod,
    this.onChanged,
  });

  final LfoSnapshot mod;
  final void Function(String param, double value)? onChanged;
}
```

No animated playhead dot. The preview is purely visual.