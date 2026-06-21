# Architectural Design & Contract: DeviceSnapshot & ProjectSnapshot Sealed-Class Refactoring

This document describes the architectural target, serialization/deserialization design, and a safe, multi-phase migration plan to refactor the giant flat `DeviceSnapshot` class in `app_flutter/lib/bridge/project_snapshot.dart` (~1500 lines) into a clean, typed Dart 3 sealed class hierarchy.

---

## 1. Feature Brief & Goals

### 1.1 Goal
Resolve the Single Responsibility Principle (SRP) violations of `DeviceSnapshot` by splitting the giant flat class containing parameters and defaults for **every single device type** into a specialized, polymorphic class hierarchy using **Dart 3 sealed classes**.

### 1.2 Subclasses of `DeviceSnapshot`
We will map the existing device types in the C++/Flutter system to distinct, type-safe Dart implementations:
1. `TrackGainDeviceSnapshot` (`type == 'track_gain'`) - Channel strip (not shown in visible device strip).
2. `OscillatorDeviceSnapshot` (`type == 'simple_oscillator'`) - Simple double-oscillator subtractive synth.
3. `SamplerDeviceSnapshot` (`type == 'simple_sampler'`) - Resampling sampler with trim start/end and region loop parameters.
4. `SubtractiveSynthDeviceSnapshot` (`type == 'subtractive_synth'`) - Complete subtractive synthesizer model.
5. `PhaseModSynthDeviceSnapshot` (`type == 'phase_mod_synth'`) - 4-operator phase modulation (FM) synth.
6. `BassSynthDeviceSnapshot` (`type == 'bass_synth'`) - Specialized subtractive bass generator.
7. `DrumGeneratorDeviceSnapshot` (Sealed base class for drum voices):
   - `KickGeneratorDeviceSnapshot` (`type == 'kick_generator'`)
   - `SnareGeneratorDeviceSnapshot` (`type == 'snare_generator'`)
   - `ClapGeneratorDeviceSnapshot` (`type == 'clap_generator'`)
   - `CymbalGeneratorDeviceSnapshot` (`type == 'cymbal_generator'`)
   - `CrashGeneratorDeviceSnapshot` (`type == 'crash_generator'`)
8. `DynamicsDeviceSnapshot` (Sealed base class for dynamics effects):
   - `GateDeviceSnapshot` (`type == 'gate'`)
   - `CompressorDeviceSnapshot` (`type == 'compressor'`)
   - `ExpanderDeviceSnapshot` (`type == 'expander'`)
   - `LimiterDeviceSnapshot` (`type == 'limiter'`)
9. `EffectDeviceSnapshot` (Sealed base class for time/modulation effects):
   - `DelayDeviceSnapshot` (`type == 'delay'`)
   - `ReverbDeviceSnapshot` (`type == 'reverb'`)
   - `ChorusDeviceSnapshot` (`type == 'chorus'`)
   - `PhaserDeviceSnapshot` (`type == 'phaser'`)

### 1.3 Key Architectural Non-Goals
* No changes to C++ engine serialization or JNI bridge protocol. This is purely a Dart side refactoring.
* No changes to UI widget files' structure during Phase 1-3. All changes to consumer code are done in a backwards-compatible manner or using explicit phases.

---

## 2. Canonical Vocabulary

| Concept | Canonical Name | Type/File | Notes |
|---------|----------------|-----------|-------|
| Root Sealed Class | `DeviceSnapshot` | `project_snapshot.dart` | Base class of all snapshots. Contains shared slot parameters. |
| Subclass Type Matcher | `type` | `String` field | Corresponds to C++ type name identifier. Used for dispatching. |
| Parameter modifier | `withParameter` | `DeviceSnapshot` method | Specialized parameter updater that returns the correctly-typed subclass. |
| Parameter copier | `copyWith` | `DeviceSnapshot` method | Each subclass implements its own specialized `copyWith` with relevant fields. |
| Factory Dispatcher | `DeviceSnapshot.fromMap` | `factory constructor` | Inspects `map['type']` and dispatches parsing to specialized subclass from-map factories. |

---

## 3. Class Hierarchy & API Contracts

The core design centers around a root `sealed class DeviceSnapshot` carrying the global properties present on all slots in the audio engine, with specialized concrete subclasses carrying parameters specific to that device type.

### 3.1 Base `DeviceSnapshot` Contract

```dart
sealed class DeviceSnapshot {
  const DeviceSnapshot({
    required this.id,
    required this.type,
    required this.gain,
    required this.pan,
    required this.bypassed,
    required this.meterGainReductionDb,
    required this.meterInputLevel,
  });

  final String id;
  final String type;
  final double gain;
  final double pan;
  final bool bypassed;
  final double meterGainReductionDb;
  final double meterInputLevel;

  /// Clamps and sets a parameter, returning an updated subclass instance.
  DeviceSnapshot withParameter(String parameterId, double value);

  /// Polymorphic copier.
  DeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
  });

  /// Factory creator dispatching to specialized types.
  factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String? ?? '';
    return switch (type) {
      'track_gain' => TrackGainDeviceSnapshot.fromMap(map),
      'simple_oscillator' => OscillatorDeviceSnapshot.fromMap(map),
      'simple_sampler' => SamplerDeviceSnapshot.fromMap(map),
      'subtractive_synth' => SubtractiveSynthDeviceSnapshot.fromMap(map),
      'phase_mod_synth' => PhaseModSynthDeviceSnapshot.fromMap(map),
      'bass_synth' => BassSynthDeviceSnapshot.fromMap(map),
      'kick_generator' => KickGeneratorDeviceSnapshot.fromMap(map),
      'snare_generator' => SnareGeneratorDeviceSnapshot.fromMap(map),
      'clap_generator' => ClapGeneratorDeviceSnapshot.fromMap(map),
      'cymbal_generator' => CymbalGeneratorDeviceSnapshot.fromMap(map),
      'crash_generator' => CrashGeneratorDeviceSnapshot.fromMap(map),
      'gate' => GateDeviceSnapshot.fromMap(map),
      'compressor' => CompressorDeviceSnapshot.fromMap(map),
      'expander' => ExpanderDeviceSnapshot.fromMap(map),
      'limiter' => LimiterDeviceSnapshot.fromMap(map),
      'delay' => DelayDeviceSnapshot.fromMap(map),
      'reverb' => ReverbDeviceSnapshot.fromMap(map),
      'chorus' => ChorusDeviceSnapshot.fromMap(map),
      'phaser' => PhaserDeviceSnapshot.fromMap(map),
      _ => throw ArgumentError('Unknown device type: $type'),
    };
  }
}
```

---

### 3.2 Concrete Subclass Structures

#### Track Gain Snapshot
```dart
class TrackGainDeviceSnapshot extends DeviceSnapshot {
  const TrackGainDeviceSnapshot({
    required super.id,
    super.type = 'track_gain',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  });
  
  // Implements copyWith and withParameter (updating gain, pan, bypassed)
}
```

#### Simple Oscillator Snapshot
```dart
class OscillatorDeviceSnapshot extends DeviceSnapshot {
  const OscillatorDeviceSnapshot({
    required super.id,
    super.type = 'simple_oscillator',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.frequencyHz,
    required this.osc1Shape,
    required this.osc2Shape,
    required this.osc1Octave,
    required this.osc1Semi,
    required this.osc1Detune,
    required this.osc2Octave,
    required this.osc2Semi,
    required this.osc2Detune,
    required this.oscMix,
    required this.osc1Sync,
    required this.osc2Sync,
    required this.noiseLevel,
    required this.oscMixMode,
    required this.unisonVoices,
    required this.unisonDetune,
    required this.filterCutoff,
    required this.filterQ,
    required this.filterMode,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
  });

  final double frequencyHz;
  final double osc1Shape;
  final double osc2Shape;
  final double osc1Octave;
  final double osc1Semi;
  final double osc1Detune;
  final double osc2Octave;
  final double osc2Semi;
  final double osc2Detune;
  final double oscMix;
  final double osc1Sync;
  final double osc2Sync;
  final double noiseLevel;
  final int oscMixMode;
  final double unisonVoices;
  final double unisonDetune;
  final double filterCutoff;
  final double filterQ;
  final int filterMode;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
}
```

#### Simple Sampler Snapshot
```dart
class SamplerDeviceSnapshot extends DeviceSnapshot {
  const SamplerDeviceSnapshot({
    required super.id,
    super.type = 'simple_sampler',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.sampleId,
    required this.trimStartSec,
    required this.trimEndSec,
    required this.regionStartSec,
    required this.regionEndSec,
    required this.rootPitch,
    required this.rootFineTune,
    required this.playbackMode,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.filterCutoff,
    required this.filterQ,
    required this.filterMode,
  });

  final String sampleId;
  final double trimStartSec;
  final double trimEndSec;
  final double regionStartSec;
  final double regionEndSec;
  final double rootPitch;
  final double rootFineTune;
  final int playbackMode;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double filterCutoff;
  final double filterQ;
  final int filterMode;
}
```

#### Subtractive Synth Snapshot
```dart
class SubtractiveSynthDeviceSnapshot extends DeviceSnapshot {
  const SubtractiveSynthDeviceSnapshot({
    required super.id,
    super.type = 'subtractive_synth',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.osc1Shape,
    required this.osc2Shape,
    required this.osc1Octave,
    required this.osc1Semi,
    required this.osc1Detune,
    required this.osc2Octave,
    required this.osc2Semi,
    required this.osc2Detune,
    required this.oscMix,
    required this.osc1Sync,
    required this.osc2Sync,
    required this.noiseLevel,
    required this.oscMixMode,
    required this.unisonVoices,
    required this.unisonDetune,
    required this.filterEnvAmount,
    required this.filterAttack,
    required this.filterDecay,
    required this.filterSustain,
    required this.filterRelease,
    required this.glideMs,
    required this.velocitySensitivity,
    required this.preHpCutoff,
    required this.preHpRes,
    required this.preDrive,
    required this.mixFeedback,
    required this.globalPitch,
    required this.filterKeyTrack,
    required this.filterDrive,
    required this.filterShaper,
    required this.filterFm,
    required this.filterShaperMode,
    required this.synthLegato,
    required this.synthMono,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.filterCutoff,
    required this.filterQ,
    required this.filterMode,
  });

  // ... All fields extracted ...
}
```

---

### 3.3 Drum Generator Subclass hierarchy

```dart
sealed class DrumGeneratorDeviceSnapshot extends DeviceSnapshot {
  const DrumGeneratorDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  });
}

class KickGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const KickGeneratorDeviceSnapshot({
    required super.id,
    super.type = 'kick_generator',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.kickModel,
    required this.kickPitch,
    required this.kickPunch,
    required this.kickDecay,
    required this.kickClick,
    required this.kickTone,
    required this.kickVelocity,
    required this.kickKeyTrack,
  });

  final double kickModel;
  final double kickPitch;
  final double kickPunch;
  final double kickDecay;
  final double kickClick;
  final double kickTone;
  final double kickVelocity;
  final double kickKeyTrack;
}

class SnareGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const SnareGeneratorDeviceSnapshot({
    required super.id,
    super.type = 'snare_generator',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.snareModel,
    required this.snareBody,
    required this.snareRing,
    required this.snareTune,
    required this.snareSnares,
    required this.snareSnap,
    required this.snareDecay,
    required this.snareVelocity,
  });

  final double snareModel;
  final double snareBody;
  final double snareRing;
  final double snareTune;
  final double snareSnares;
  final double snareSnap;
  final double snareDecay;
  final double snareVelocity;
}

class ClapGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const ClapGeneratorDeviceSnapshot({
    required super.id,
    super.type = 'clap_generator',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.clapBursts,
    required this.clapSpread,
    required this.clapTone,
    required this.clapRoom,
    required this.clapDecay,
    required this.clapVelocity,
  });

  final double clapBursts;
  final double clapSpread;
  final double clapTone;
  final double clapRoom;
  final double clapDecay;
  final double clapVelocity;
}

class CymbalGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const CymbalGeneratorDeviceSnapshot({
    required super.id,
    super.type = 'cymbal_generator',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.cymbalModel,
    required this.cymbalColor,
    required this.cymbalDecay,
    required this.cymbalVelocity,
    required this.cymbalWidth,
  });

  final double cymbalModel;
  final double cymbalColor;
  final double cymbalDecay;
  final double cymbalVelocity;
  final double cymbalWidth;
}

class CrashGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const CrashGeneratorDeviceSnapshot({
    required super.id,
    super.type = 'crash_generator',
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.crashModel,
    required this.crashColor,
    required this.crashSpread,
    required this.crashDecay,
    required this.crashVelocity,
  });

  final double crashModel;
  final double crashColor;
  final double crashSpread;
  final double crashDecay;
  final double crashVelocity;
}
```

---

## 4. Multi-Phase Migration & Integration Plan

Refactoring an entire domain hierarchy is risky. To ensure complete safety, we divide the refactoring into 5 sequential phases where **each phase leaves the code in a compile-green and test-green state**.

```
[Phase 1: Stub Extension Interface] ──► [Phase 2: Extract Subclasses & factory] ──► [Phase 3: Migrate withParameter]
                                                                                               │
[Phase 5: Remove Old Flat Class Shim] ◄── [Phase 4: Incrementally Migrate UI panels] ◄─────────┘
```

### Phase 1: Create Stub Extension Interface (Bridge compatibility)
To prevent compile-errors in UI files that currently reference properties off `DeviceSnapshot` which they are not supposed to have (e.g. `sampler_device_strip` reading `device.attack` or `dynamics_fx_panels` reading `device.compAttack` on a generic `DeviceSnapshot` reference), we create a **temporary shim extension** on `DeviceSnapshot` that defines getters/setters/copyWith fields for **all legacy parameters** with fallback values.
* **Outcome:** The codebase compiles perfectly even if the base class is sealed and instances are subclassed, because any subclass reference falling back to a `DeviceSnapshot` type can still invoke the extension getters.
* **Parallel-safe:** Yes, this is a single file modification that makes the rest of the project immediately safe for polymorphic transitions.

### Phase 2: Implement Sealed Subclasses and `fromMap` Factory
With the extension from Phase 1 in place, we define the `sealed class DeviceSnapshot` and all concrete subclasses.
* Write custom `fromMap` factory methods for each concrete subclass.
* Update `DeviceSnapshot.fromMap` to dispatch to the correct subclass parser using a `switch` on the `type` string.
* Keep the Phase 1 extension alive.
* **Outcome:** Parsed JSON objects are now real typed subclasses! Polymorphic behavior is fully functional under the hood. All tests pass since the extension delegates missing properties gracefully.

### Phase 3: Migrate `withParameter` and `copyWith` to Polymorphism
Implement specialized `withParameter` methods on each subclass.
* For example, `KickGeneratorDeviceSnapshot.withParameter` will only accept kick parameter IDs, routing them to its kick-specific `copyWith` method and returning an updated `KickGeneratorDeviceSnapshot`.
* If a general parameter like `bypass`, `gain`, or `pan` is modified, it updates on the subclass.
* Any unknown parameters return the unmodified snapshot `this`.
* **Outcome:** State modifications are now fully polymorphic and type-safe.

### Phase 4: Clean Up UI Panels and Screens
With typed subclasses fully active, we can go through each specialized panel and change its bound device reference to the **concrete subclass type** instead of the generic `DeviceSnapshot`.
* In `app_flutter/lib/features/device_strip/bass_synth_device_panel.dart`, change `final DeviceSnapshot device` to `final BassSynthDeviceSnapshot device`.
* Clean up getters or casts. The widget now uses pure subclass properties.
* Do this step-by-step, panel by panel.

### Phase 5: Deprecate and Remove the Extension Shim
Once all UI panels and test cases are migrated to read from the concrete subclasses directly:
* Delete the Phase 1 compatibility extension on `DeviceSnapshot`.
* Now, any attempt to read `kickPitch` from a `SamplerDeviceSnapshot` results in a **compile-time error**, achieving complete type safety and strict separation of concerns.

---

## 5. File Ownership Table

To ensure clear work division for implementation workers:

| File/path | Owner Work Package | Allowed Changes | Forbidden Changes |
| --------- | ------------------ | --------------- | ----------------- |
| `app_flutter/lib/bridge/project_snapshot.dart` | Phase 1, 2, 3, 5 | Complete rewrite of `DeviceSnapshot` class and new subclasses. | Do not touch TrackSnapshot/ProjectSnapshot fields unrelated to devices. |
| `app_flutter/lib/features/device_strip/bass_synth_device_panel.dart` | Phase 4 | Update `DeviceSnapshot` type to `BassSynthDeviceSnapshot`. | No DSP/modulator logic changes. |
| `app_flutter/lib/features/device_strip/kick_generator_device_panel.dart` | Phase 4 | Update `DeviceSnapshot` type to `KickGeneratorDeviceSnapshot`. | No DSP/modulator logic changes. |
| `app_flutter/lib/features/device_strip/dynamics_fx_panels.dart` | Phase 4 | Update references to typed dynamics snapshots (Compressor, Expander, Gate, Limiter). | No layout/meter rendering changes. |
| `app_flutter/lib/features/device_strip/time_fx_panels.dart` | Phase 4 | Update references to typed effect snapshots (Delay, Reverb, Chorus, Phaser). | No layout/knob rendering changes. |
| `app_flutter/test/bass_synth_snapshot_test.dart` | Phase 4, 5 | Update assertions to target `BassSynthDeviceSnapshot`. | No test coverage reductions. |

---

## 6. Contract Gaps & Risks

1. **Automation Links:** `visibleDevices` and tracks filter devices by matching types. Ensure that `type` remains an exact match string so that other layout and utility systems do not break.
2. **State Updates from JNI:** When the native layer pushes a live project snapshot (for meters or parameter adjustments), Dart constructs a whole new snapshot tree using `ProjectSnapshot.fromMap`. The performance of polymorphic construction should be monitored; however, since Dart 3 sealed switch matches are compiler-optimized, it is expected to have identical or superior performance to the previous flat-map approach.
3. **Meters Updates:** `withMergedDeviceMeters` copies values of `meterGainReductionDb` and `meterInputLevel`. The base class must provide these fields so that generic meter merging remains unified without downcasting.
