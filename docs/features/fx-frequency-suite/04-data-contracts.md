# Frequency FX Suite — Data Contracts

## C++ Filter Params (audio-thread)

```cpp
struct FilterParams {
    float cutoffHz = 1000.0f;      // 20 – 20000 Hz
    float resonance = 0.707f;      // Q factor
    int filterMode = 0;            // 0=LP, 1=HP, 2=BP, 3=Notch
};
```

## C++ Filter Instance (control-thread)

```cpp
struct FilterInstance {
    float ffxCutoff = 0.6f;        // normalized 0-1 → 20-20000 Hz
    float ffxResonance = 0.3f;     // normalized 0-1 → Q 0.1-20
    float ffxFilterMode = 0.0f;    // normalized 0-1 → 0=LP, 1=HP, 2=BP, 3=Notch

    FilterParams toPlaybackParams() const {
        FilterParams p;
        p.cutoffHz = normalizedToFrequency(ffxCutoff);
        p.resonance = normalizedToQ(ffxResonance);
        p.filterMode = static_cast<int>(std::lround(ffxFilterMode * 3.0f));
        return p;
    }
};
```

## C++ Filter Runtime (audio-thread state)

```cpp
struct FilterRuntime {
    BiquadState left;   // biquad state left channel
    BiquadState right;  // biquad state right channel
};
```

## C++ 4-Band EQ Params

```cpp
struct FourBandEqBandParams {
    float frequencyHz = 1000.0f;
    float gainDb = 0.0f;
    float q = 0.707f;
};

struct FourBandEqParams {
    FourBandEqBandParams bands[4];  // 0=LowShelf, 1=LowMid(Peak), 2=HighMid(Peak), 3=HighShelf
};
```

## C++ 4-Band EQ Instance

```cpp
struct FourBandEqInstance {
    float ffxBand1Freq = 0.15f;    // normalized → Hz
    float ffxBand1Gain = 0.5f;     // normalized → dB (-24 to +24)
    float ffxBand1Q = 0.5f;        // normalized → Q
    float ffxBand2Freq = 0.35f;
    float ffxBand2Gain = 0.5f;
    float ffxBand2Q = 0.5f;
    float ffxBand3Freq = 0.6f;
    float ffxBand3Gain = 0.5f;
    float ffxBand3Q = 0.5f;
    float ffxBand4Freq = 0.85f;
    float ffxBand4Gain = 0.5f;
    float ffxBand4Q = 0.5f;

    FourBandEqParams toPlaybackParams() const;
};
```

## C++ 4-Band EQ Runtime

```cpp
struct FourBandEqRuntime {
    BiquadState bands[4][2];  // [band][channel] biquad states
};
```

## C++ Frequency Shifter Params

```cpp
struct FrequencyShifterParams {
    float shiftHz = 0.0f;     // -2000 to +2000 Hz
};
```

## C++ Frequency Shifter Instance

```cpp
struct FrequencyShifterInstance {
    float ffxShift = 0.5f;    // normalized 0-1 → -2000 to +2000 Hz (0.5 = 0)

    FrequencyShifterParams toPlaybackParams() const {
        FrequencyShifterParams p;
        p.shiftHz = (ffxShift - 0.5f) * 4000.0f;
        return p;
    }
};
```

## C++ Frequency Shifter Runtime

```cpp
struct FrequencyShifterRuntime {
    double phaseL = 0.0;   // SSB phase accumulator left
    double phaseR = 0.0;   // SSB phase accumulator right
};
```

## JSON Serialization Schema (engine-side, C++ produces this)

### Filter (slotToVar output)

```json
{
    "id": "device-uuid",
    "type": "filter",
    "parameters": {
        "gain": 1.0,
        "pan": 0.5,
        "bypass": 0.0,
        "ffxCutoff": 0.6,
        "ffxResonance": 0.3,
        "ffxFilterMode": 0.0
    },
    "meters": {
        "gainReductionDb": 0.0,
        "inputLevel": 0.0
    }
}
```

### 4-Band EQ (slotToVar output)

```json
{
    "id": "device-uuid",
    "type": "four_band_eq",
    "parameters": {
        "gain": 1.0, "pan": 0.5, "bypass": 0.0,
        "ffxBand1Freq": 0.15, "ffxBand1Gain": 0.5, "ffxBand1Q": 0.5,
        "ffxBand2Freq": 0.35, "ffxBand2Gain": 0.5, "ffxBand2Q": 0.5,
        "ffxBand3Freq": 0.6,  "ffxBand3Gain": 0.5, "ffxBand3Q": 0.5,
        "ffxBand4Freq": 0.85, "ffxBand4Gain": 0.5, "ffxBand4Q": 0.5
    },
    "meters": { "gainReductionDb": 0.0, "inputLevel": 0.0 }
}
```

### Frequency Shifter (slotToVar output)

```json
{
    "id": "device-uuid",
    "type": "frequency_shifter",
    "parameters": {
        "gain": 1.0, "pan": 0.5, "bypass": 0.0,
        "ffxShift": 0.5
    },
    "meters": { "gainReductionDb": 0.0, "inputLevel": 0.0 }
}
```

## Flutter-side DeviceSnapshot (sealed class hierarchy)

> **NOTE**: As of the `refactor(bridge): introduce polymorphic DeviceSnapshot sealed hierarchy` commit, `DeviceSnapshot` is a `sealed class` in `app_flutter/lib/bridge/device_snapshots.dart`. New device types must:
>
> 1. Add a new **sealed subclass** for the device family (if not already covered), OR extend an existing sealed subclass (e.g. `DynamicsDeviceSnapshot`, `EffectDeviceSnapshot`).
> 2. Add a concrete **leaf class** for the specific device with its own `fromMap`, `copyWith`, `withParameter`.
> 3. Add a case to the `DeviceSnapshot.fromMap` factory `switch (type)`.

### Sealed hierarchy placement

Frequency FX devices are **stereo effects**, conceptually closest to the existing **time-based effects** (`EffectDeviceSnapshot` sealed class — parent of `DelayDeviceSnapshot`, `ReverbDeviceSnapshot`, `ChorusDeviceSnapshot`, `PhaserDeviceSnapshot`). They use the same chrome (`DynamicsInputPanel` + `DynamicsOutputPanel`).

**Decision**: introduce a new sealed class `FrequencyFxDeviceSnapshot` (sibling of `EffectDeviceSnapshot`) under `DeviceSnapshot`. This keeps the family structure clean and allows future frequency FX devices (e.g. comb filter, wah, vocoder) to slot in.

```dart
// New sealed class in device_snapshots.dart
sealed class FrequencyFxDeviceSnapshot extends DeviceSnapshot {
  const FrequencyFxDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  });
}
```

### Concrete subclasses

```dart
class FilterDeviceSnapshot extends FrequencyFxDeviceSnapshot {
  const FilterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.ffxCutoff,
    required this.ffxResonance,
    required this.ffxFilterMode,
  }) : super(type: 'filter');

  final double ffxCutoff;       // 0-1 normalized → 20-20000 Hz
  final double ffxResonance;    // 0-1 normalized → Q 0.1-20
  final double ffxFilterMode;   // 0-1 normalized → 0=LP, 0.33=HP, 0.67=BP, 1=Notch

  factory FilterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) { /* ... */ }

  @override FilterDeviceSnapshot copyWith({...}) { /* ... */ }

  @override FilterDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'ffxCutoff' => copyWith(ffxCutoff: value.clamp(0.0, 1.0)),
      'ffxResonance' => copyWith(ffxResonance: value.clamp(0.0, 1.0)),
      'ffxFilterMode' => copyWith(ffxFilterMode: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class FourBandEqDeviceSnapshot extends FrequencyFxDeviceSnapshot {
  const FourBandEqDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.ffxBand1Freq,
    required this.ffxBand1Gain,
    required this.ffxBand1Q,
    required this.ffxBand2Freq,
    required this.ffxBand2Gain,
    required this.ffxBand2Q,
    required this.ffxBand3Freq,
    required this.ffxBand3Gain,
    required this.ffxBand3Q,
    required this.ffxBand4Freq,
    required this.ffxBand4Gain,
    required this.ffxBand4Q,
  }) : super(type: 'four_band_eq');

  final double ffxBand1Freq, ffxBand1Gain, ffxBand1Q;
  final double ffxBand2Freq, ffxBand2Gain, ffxBand2Q;
  final double ffxBand3Freq, ffxBand3Gain, ffxBand3Q;
  final double ffxBand4Freq, ffxBand4Gain, ffxBand4Q;

  factory FourBandEqDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) { /* ... */ }
  @override FourBandEqDeviceSnapshot copyWith({...}) { /* ... */ }
  @override FourBandEqDeviceSnapshot withParameter(String parameterId, double value) { /* ... */ }
}

class FrequencyShifterDeviceSnapshot extends FrequencyFxDeviceSnapshot {
  const FrequencyShifterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.ffxShift,
  }) : super(type: 'frequency_shifter');

  final double ffxShift;   // 0-1 normalized → -2000 to +2000 Hz (0.5 = 0)

  factory FrequencyShifterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) { /* ... */ }
  @override FrequencyShifterDeviceSnapshot copyWith({...}) { /* ... */ }
  @override FrequencyShifterDeviceSnapshot withParameter(String parameterId, double value) { /* ... */ }
}
```

### Factory dispatch update

Add three new cases to `DeviceSnapshot.fromMap()` in `device_snapshots.dart`:

```dart
factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
  final type = map['type'] as String? ?? '';
  return switch (type) {
    // ... existing cases ...
    'filter' => FilterDeviceSnapshot.fromMap(map),
    'four_band_eq' => FourBandEqDeviceSnapshot.fromMap(map),
    'frequency_shifter' => FrequencyShifterDeviceSnapshot.fromMap(map),
    _ => throw ArgumentError('Unknown device type: $type'),
  };
}
```

### Defaults (used by `fromMap` and Flutter widgets)

| Field | Default |
|-------|---------|
| `ffxCutoff` | 0.6 |
| `ffxResonance` | 0.3 |
| `ffxFilterMode` | 0.0 |
| `ffxBand1Freq` | 0.15 |
| `ffxBand1Gain` | 0.5 |
| `ffxBand1Q` | 0.5 |
| `ffxBand2Freq` | 0.35 |
| `ffxBand2Gain` | 0.5 |
| `ffxBand2Q` | 0.5 |
| `ffxBand3Freq` | 0.6 |
| `ffxBand3Gain` | 0.5 |
| `ffxBand3Q` | 0.5 |
| `ffxBand4Freq` | 0.85 |
| `ffxBand4Gain` | 0.5 |
| `ffxBand4Q` | 0.5 |
| `ffxShift` | 0.5 |