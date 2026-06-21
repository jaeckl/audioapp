# Data Contracts: Phase Modulation Synth Device

## JSON snapshot schema (engine-side)

The PM synth serializes via `slotToVar()` / `varToSlot()` using `juce::DynamicObject`. Fields are emitted inside the `parameters` map of the standard project snapshot.

### Engine-side JSON structure (emitted by C++)

```json
{
  "id": "device-uuid",
  "type": "phase_mod_synth",
  "parameters": {
    "gain": 1.0,
    "pan": 0.5,
    "bypass": false,
    // Common filter fields (reused from existing DTO)
    "filterCutoff": 0.85,
    "filterQ": 0.25,
    "filterMode": 0,
    "filterEnvAmount": 0.5,
    "filterAttack": 0.05,
    "filterDecay": 0.35,
    "filterSustain": 0.4,
    "filterRelease": 0.45,
    "filterKeyTrack": 0.0,
    // Common amp fields (reused from existing DTO)
    "attack": 0.01,
    "decay": 0.3,
    "sustain": 0.75,
    "release": 0.35,
    // Operator 1
    "pmOp1Ratio": 0.0625,
    "pmOp1Fine": 0.5,
    "pmOp1Level": 0.8,
    "pmOp1Wave": 0.0,
    "pmOp1Attack": 0.01,
    "pmOp1Decay": 0.3,
    "pmOp1Sustain": 0.8,
    "pmOp1Release": 0.4,
    "pmOp1VelSense": 1.0,
    "pmOp1KeyTrack": 0.0,
    // Operator 2
    "pmOp2Ratio": 0.4375,
    "pmOp2Fine": 0.5,
    "pmOp2Level": 0.4,
    "pmOp2Wave": 0.0,
    "pmOp2Attack": 0.01,
    "pmOp2Decay": 0.3,
    "pmOp2Sustain": 0.8,
    "pmOp2Release": 0.4,
    "pmOp2VelSense": 1.0,
    "pmOp2KeyTrack": 0.0,
    // Operator 3
    "pmOp3Ratio": 0.75,
    "pmOp3Fine": 0.5,
    "pmOp3Level": 0.0,
    "pmOp3Wave": 0.0,
    "pmOp3Attack": 0.01,
    "pmOp3Decay": 0.3,
    "pmOp3Sustain": 0.8,
    "pmOp3Release": 0.4,
    "pmOp3VelSense": 1.0,
    "pmOp3KeyTrack": 0.0,
    // Operator 4
    "pmOp4Ratio": 0.375,
    "pmOp4Fine": 0.5,
    "pmOp4Level": 0.0,
    "pmOp4Wave": 0.0,
    "pmOp4Attack": 0.01,
    "pmOp4Decay": 0.3,
    "pmOp4Sustain": 0.8,
    "pmOp4Release": 0.4,
    "pmOp4VelSense": 1.0,
    "pmOp4KeyTrack": 0.0,
    // Global
    "pmAlgoIndex": 0,
    "pmFeedback": 0.0,
    "pmUnisonVoices": 0.0,
    "pmUnisonDetune": 0.15,
    "pmGlide": 0.0,
    "pmMono": 0.0,
    "pmLegato": 0.0,
    "pmMasterVol": 0.85,
    // LFO
    "pmLfoRate": 0.2,
    "pmLfoShape": 0.0,
    "pmLfoAmount": 0.0,
    "pmLfoDest": 0,
    "pmVibratoDepth": 0.0,
    "pmVibratoRate": 0.3
  },
  "meters": {}
}
```

### Ratio value mapping (normalized ↔ actual ratio)

The `pmOpXRatio` parameter is stored normalized [0, 1] in the instance and JSON, but converted to discrete ratio values in `PhaseModSynthParams`:

| Normalized | Discrete value | Actual ratio |
|-----------|---------------|--------------|
| 0.0 | 0 | 0.5 |
| 0.0625 | 1 | 1.0 |
| 0.125 | 2 | 1.5 |
| 0.25 | 3 | 2.0 |
| 0.375 | 4 | 3.0 |
| 0.5 | 5 | 4.0 |
| 0.625 | 6 | 5.0 |
| 0.75 | 7 | 6.0 |
| 1.0 | 8 | 8.0 |

Mapping function:
```cpp
float ratioNormToValue(float norm) {
    constexpr float ratios[] = {0.5f, 1.0f, 1.5f, 2.0f, 3.0f, 4.0f, 5.0f, 6.0f, 8.0f};
    constexpr int count = sizeof(ratios) / sizeof(ratios[0]);
    const int idx = std::clamp(static_cast<int>(std::lround(norm * (count - 1))), 0, count - 1);
    return ratios[idx];
}
```

### Fine mapping (normalized ↔ cents)

```cpp
float fineNormToCents(float norm) {
    // Maps 0..1 → -50..+50 cents
    return (norm - 0.5f) * 100.0f;
}
```

### Waveform mapping (normalized ↔ waveform)

| Normalized | Waveform |
|-----------|----------|
| 0.0 | Sine |
| 0.25 | Triangle |
| 0.5 | Saw |
| 0.75 | Square |
| 1.0 | Noise |

## PhaseModSynthParams (audio-thread struct)

```cpp
struct PhaseModSynthOperatorParams {
    float ratio = 1.0f;       // actual frequency ratio (0.5, 1, 1.5, 2, 3, 4, 5, 6, 8)
    float fine = 0.0f;        // detune in cents (-50..+50)
    float level = 0.0f;       // output level [0, 1]
    float wave = 0.0f;        // waveform morph [0, 1] (sine→tri→saw→square→noise)
    float attack = 0.01f;
    float decay = 0.3f;
    float sustain = 0.8f;
    float release = 0.4f;
    float velocitySense = 1.0f;
    float keyTrack = 0.0f;
};

struct PhaseModSynthParams {
    float gain = 1.0f;
    float masterVol = 0.85f;
    int algoIndex = 0;                        // 0..7
    float feedback = 0.0f;                    // self-feedback for op1 [0, 1]
    PhaseModSynthOperatorParams operators[4];  // 4 operators

    // Filter
    int filterMode = 0;
    float filterCutoff = 0.85f;
    float filterQ = 0.25f;
    float filterEnvAmount = 0.5f;
    float filterAttack = 0.05f;
    float filterDecay = 0.35f;
    float filterSustain = 0.4f;
    float filterRelease = 0.45f;
    float filterKeyTrack = 0.0f;

    // Amp
    float ampAttack = 0.01f;
    float ampDecay = 0.3f;
    float ampSustain = 0.75f;
    float ampRelease = 0.35f;

    // Performance
    float glideMs = 0.0f;
    float velocitySensitivity = 1.0f;
    float unisonVoices = 0.0f;
    float unisonDetune = 0.15f;
    float synthMono = 0.0f;
    float synthLegato = 0.0f;

    // Global
    // (pan handled at DeviceSlot level by existing chain)

    // LFO
    float lfoRate = 0.2f;
    int lfoShape = 0;          // 0=sine, 1=tri, 2=saw, 3=square, 4=s&h
    float lfoAmount = 0.0f;
    int lfoDest = 0;           // 0=off, 1=pitch, 2=filter, 3=amp, 4=pmAmount
    float vibratoDepth = 0.0f;
    float vibratoRate = 0.3f;
};
```

## PhaseModSynthRuntime (audio-thread voice state)

```cpp
static constexpr int kPhaseModMaxVoices = 8;

struct PhaseModSynthVoiceRuntime {
    uint8_t active = 0;
    int pitch = 60;
    int noteKey = -1;
    float velocity = 100.0f;
    double startBeat = 0.0;
    double releaseBeat = -1.0;

    // Per-operator phase accumulators (one per unison voice)
    float opPhases[4]{};         // current phase for each operator
    float envelopeValues[4]{};   // current envelope value for each operator
    int envelopePhase[4]{};      // 0=attack, 1=decay, 2=sustain, 3=release, 4=done
    float envelopeStart[4]{};    // value at start of current envelope phase
    float prevOpOutput[4]{};     // previous sample's output for feedback

    // Runtime state
    float currentHz = 440.0f;
    float targetHz = 440.0f;
    float currentPan = 0.5f;
    float lfoPhase = 0.0f;
    float smoothCutoffHz = -1.0f;
    float smoothQ = -1.0f;

    BiquadCoeffs cachedFilterCoeffs{};
    float cachedFilterCutoffHz = -1.0f;
    float cachedFilterQ = -1.0f;
    int cachedFilterMode = -1;
    BiquadState filterState{};
    BiquadState filterState2{};
};

struct PhaseModSynthRuntime {
    PhaseModSynthVoiceRuntime voices[kPhaseModMaxVoices]{};
    int stealIndex = 0;
};
```

## Flutter-side DeviceSnapshot fields

All PM fields added to `DeviceSnapshot` class:
- 40 operator fields (10 params × 4 operators), prefixed `pmOp1`-`pmOp4`
- 14 global/algorithm/LFO fields, prefixed `pm`

Default values match engine-side defaults exactly.

### DeviceSnapshot.fromMap reading

```dart
// Example pattern for op1 fields:
pmOp1Ratio: (params['pmOp1Ratio'] as num?)?.toDouble() ?? 0.0625,
pmOp1Fine: (params['pmOp1Fine'] as num?)?.toDouble() ?? 0.5,
pmOp1Level: (params['pmOp1Level'] as num?)?.toDouble() ?? 0.8,
pmOp1Wave: (params['pmOp1Wave'] as num?)?.toDouble() ?? 0.0,
pmOp1Attack: (params['pmOp1Attack'] as num?)?.toDouble() ?? 0.01,
// ... repeat for op2, op3, op4 ...

// Global fields:
pmAlgoIndex: (params['pmAlgoIndex'] as num?)?.toInt() ?? 0,
pmFeedback: (params['pmFeedback'] as num?)?.toDouble() ?? 0.0,
pmMasterVol: (params['pmMasterVol'] as num?)?.toDouble() ?? 0.85,
pmLfoRate: (params['pmLfoRate'] as num?)?.toDouble() ?? 0.2,
// etc.
```

### DeviceSnapshot.copyWith

All 54 PM fields added to `copyWith()`.

### DeviceSnapshot.withParameter routing

```dart
// Example:
case 'pmOp1Level':
  return copyWith(pmOp1Level: value.clamp(0.0, 1.0));
case 'pmAlgoIndex':
  return copyWith(pmAlgoIndex: value.round().clamp(0, 7));
case 'pmFeedback':
  return copyWith(pmFeedback: value.clamp(0.0, 1.0));
// ... all 54 PM fields + existing shared fields
```

## LiveInstrumentSnapshot — new field

Add to `LiveInstrumentSnapshot`:
```cpp
PhaseModSynthParams phaseMod;
```

## DeviceVariantParams — new variant entry

```cpp
// In DeviceChain.hpp, DeviceVariantParams gets new entry
// Already covered in API contracts
```