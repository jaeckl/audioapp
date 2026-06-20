# Data Contracts: Bass Synth Device

## JSON snapshot schema

The bass synth serializes as a `DeviceState` with `type = "bass_synth"`. Fields are emitted inside the `parameters` map of the standard project snapshot.

### Engine-side JSON structure (emitted by C++)

```json
{
  "id": "device-uuid",
  "type": "bass_synth",
  "parameters": {
    "gain": 1.0,
    "pan": 0.5,
    "bypass": false,
    // Common synth fields (reused from DeviceState for modulation/automation)
    "attack": 0.02,
    "sustain": 0.8,
    "release": 0.35,
    "glideMs": 0.0,
    "filterCutoff": 0.85,
    "filterEnvAmount": 0.6,
    "filterDecay": 0.4,
    // Bass-specific fields (new in DeviceState)
    "bassOscShape": 0.3,
    "bassSubMix": 0.5,
    "bassSubOctave": 0,
    "bassNoise": 0.0,
    "bassFilterResonance": 0.25,
    "bassDrive": 0.0,
    "bassSquash": 0.0,
    "bassOctave": 2,
    "bassVelocitySense": 1.0
  },
  "meters": {}
}
```

### Flutter-side DeviceSnapshot serialization

Add these fields to `DeviceSnapshot` (in `project_snapshot.dart`):

```dart
class DeviceSnapshot {
  // ... existing fields ...

  // New bass fields
  final double bassOscShape;
  final double bassSubMix;
  final int bassSubOctave;
  final double bassNoise;
  final double bassFilterResonance;
  final double bassDrive;
  final double bassSquash;
  final int bassOctave;
  final double bassVelocitySense;
}
```

### DeviceSnapshot.fromMap reading

```dart
bassOscShape: (params['bassOscShape'] as num?)?.toDouble() ?? 0.3,
bassSubMix: (params['bassSubMix'] as num?)?.toDouble() ?? 0.5,
bassSubOctave: (params['bassSubOctave'] as num?)?.toInt() ?? 0,
bassNoise: (params['bassNoise'] as num?)?.toDouble() ?? 0.0,
bassFilterResonance: (params['bassFilterResonance'] as num?)?.toDouble() ?? 0.25,
bassDrive: (params['bassDrive'] as num?)?.toDouble() ?? 0.0,
bassSquash: (params['bassSquash'] as num?)?.toDouble() ?? 0.0,
bassOctave: (params['bassOctave'] as num?)?.toInt() ?? 2,
bassVelocitySense: (params['bassVelocitySense'] as num?)?.toDouble() ?? 1.0,
```

### DeviceSnapshot.copyWith

Add all bass fields to `copyWith()`. Add defaults matching the JSON reading.

### DeviceSnapshot.withParameter routing

```dart
case 'bassOscShape':
  return copyWith(bassOscShape: value.clamp(0.0, 1.0));
case 'bassSubMix':
  return copyWith(bassSubMix: value.clamp(0.0, 1.0));
case 'bassSubOctave':
  return copyWith(bassSubOctave: value.round().clamp(0, 2));
case 'bassNoise':
  return copyWith(bassNoise: value.clamp(0.0, 1.0));
case 'bassFilterResonance':
  return copyWith(bassFilterResonance: value.clamp(0.0, 1.0));
case 'bassDrive':
  return copyWith(bassDrive: value.clamp(0.0, 1.0));
case 'bassSquash':
  return copyWith(bassSquash: value.clamp(0.0, 1.0));
case 'bassOctave':
  return copyWith(bassOctave: value.round().clamp(0, 4));
case 'bassVelocitySense':
  return copyWith(bassVelocitySense: value.clamp(0.0, 1.0));
```

## DeviceState.hpp (C++ DTO) new fields

Add to `DeviceState` struct:

```cpp
float bassOscShape = 0.3f;
float bassSubMix = 0.5f;
int bassSubOctave = 0;
float bassNoise = 0.0f;
float bassFilterResonance = 0.25f;
float bassDrive = 0.0f;
float bassSquash = 0.0f;
int bassOctave = 2;
float bassVelocitySense = 1.0f;
```

## DeviceVariantParams — no new variant entry

`DeviceVariantParams` already contains `SubtractiveSynthParams`. The BassSynth's `buildPlaybackNode` fills ``out.params = SubtractiveSynthParams``, so no new `DeviceVariantParams` variant entry is needed. The dispatch happens via `DeviceNodeKind::BassSynth` matching the same `case` handler as `DeviceNodeKind::SubtractiveSynth` in `processDeviceChain`.

## LiveInstrumentSnapshot — no new field

`LiveInstrumentSnapshot` already has a `subtractive` field. The BassSynth's `buildLiveInstrument` fills `out.subtractive = ...`, so no new field is needed. Dispatch via `LiveInstrumentKind::BassSynth`.