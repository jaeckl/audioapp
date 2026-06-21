# Frequency FX Suite — Data Contracts

## FilterParams (audio-thread)

```cpp
struct FilterParams {
    float cutoffHz = 1000.0f;      // 20 – 20000 Hz
    float resonance = 0.707f;      // Q factor
    int filterMode = 0;            // 0=LP, 1=HP, 2=BP, 3=Notch
};
```

## FilterInstance (control-thread)

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

## FilterRuntime (audio-thread state)

```cpp
struct FilterRuntime {
    BiquadState left;   // biquad state left channel
    BiquadState right;  // biquad state right channel
};
```

## FourBandEqBandParams

```cpp
struct FourBandEqBandParams {
    float frequencyHz = 1000.0f;
    float gainDb = 0.0f;
    float q = 0.707f;
};
```

## FourBandEqParams (audio-thread)

```cpp
struct FourBandEqParams {
    FourBandEqBandParams bands[4];  // 0=LowShelf, 1=LowMid(Peak), 2=HighMid(Peak), 3=HighShelf
};
```

## FourBandEqInstance (control-thread)

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

## FourBandEqRuntime (audio-thread state)

```cpp
struct FourBandEqRuntime {
    BiquadState bands[4][2];  // [band][channel] biquad states
};
```

## FrequencyShifterParams (audio-thread)

```cpp
struct FrequencyShifterParams {
    float shiftHz = 0.0f;     // -2000 to +2000 Hz
};
```

## FrequencyShifterInstance (control-thread)

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

## FrequencyShifterRuntime (audio-thread state)

```cpp
struct FrequencyShifterRuntime {
    double phaseL = 0.0;   // SSB phase accumulator left
    double phaseR = 0.0;   // SSB phase accumulator right
};
```

## JSON Serialization Schema

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

## DeviceSnapshot Flat Fields (project_snapshot.dart)

New fields to add to `DeviceSnapshot`:

```dart
// Filter
final double ffxCutoff;
final double ffxResonance;
final double ffxFilterMode;

// 4-Band EQ
final double ffxBand1Freq;
final double ffxBand1Gain;
final double ffxBand1Q;
final double ffxBand2Freq;
final double ffxBand2Gain;
final double ffxBand2Q;
final double ffxBand3Freq;
final double ffxBand3Gain;
final double ffxBand3Q;
final double ffxBand4Freq;
final double ffxBand4Gain;
final double ffxBand4Q;

// Frequency Shifter
final double ffxShift;
```

All with defaults corresponding to the C++ Instance defaults (see above). Parsed from JSON `parameters` object in `DeviceSnapshot.fromMap()`.