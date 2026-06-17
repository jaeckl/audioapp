/// Engine project snapshot from C++.
library;

export 'clip_snapshots.dart';
export 'timeline_clip.dart';

import 'clip_snapshots.dart';

class ProjectSnapshot {
  const ProjectSnapshot({
    required this.bpm,
    required this.selectedTrackId,
    required this.playheadBeats,
    required this.playing,
    required this.loopEnabled,
    required this.loopLengthBeats,
    required this.recordArmed,
    required this.master,
    required this.samples,
    required this.tracks,
    this.lfos = const [],
    this.modEdges = const [],
  });

  final int bpm;
  final String selectedTrackId;
  final double playheadBeats;
  final bool playing;
  final bool loopEnabled;
  final double loopLengthBeats;
  final bool recordArmed;
  final MasterTrackSnapshot master;
  final List<SampleLibraryEntrySnapshot> samples;
  final List<TrackSnapshot> tracks;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;

  factory ProjectSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final snapshot = map['snapshot'] as Map<dynamic, dynamic>? ?? map;
    final tracksRaw = snapshot['tracks'] as List<dynamic>? ?? [];
    final samplesRaw = snapshot['samples'] as List<dynamic>? ?? [];
    final lfosRaw = snapshot['lfos'] as List<dynamic>? ?? [];
    final modEdgesRaw = snapshot['modEdges'] as List<dynamic>? ?? [];
    return ProjectSnapshot(
      bpm: (snapshot['bpm'] as num?)?.toInt() ?? 120,
      selectedTrackId: snapshot['selectedTrackId'] as String? ?? '',
      playheadBeats: (snapshot['playheadBeats'] as num?)?.toDouble() ?? 0.0,
      playing: snapshot['playing'] == true,
      loopEnabled: snapshot['loopEnabled'] != false,
      loopLengthBeats: (snapshot['loopLengthBeats'] as num?)?.toDouble() ?? 16.0,
      recordArmed: snapshot['recordArmed'] == true,
      master: MasterTrackSnapshot.fromMap(snapshot['master'] as Map<dynamic, dynamic>?),
      samples: samplesRaw
          .map((s) => SampleLibraryEntrySnapshot.fromMap(s as Map<dynamic, dynamic>))
          .toList(),
      tracks: tracksRaw
          .map((t) => TrackSnapshot.fromMap(t as Map<dynamic, dynamic>))
          .toList(),
      lfos: lfosRaw
          .map((l) => LfoSnapshot.fromMap(l as Map<dynamic, dynamic>))
          .toList(),
      modEdges: modEdgesRaw
          .map((e) => ModulationEdgeSnapshot.fromMap(e as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  TrackSnapshot? get selectedTrack {
    for (final track in tracks) {
      if (track.id == selectedTrackId) {
        return track;
      }
    }
    return tracks.isEmpty ? null : tracks.first;
  }
}

extension TrackSnapshotDevices on TrackSnapshot {
  /// FX/instrument devices shown in the arrangement device strip (excludes track_gain).
  Iterable<DeviceSnapshot> get visibleDevices =>
      devices.where((device) => device.type != 'track_gain');

  DeviceSnapshot? get samplerDevice {
    for (final device in visibleDevices) {
      if (device.type == 'simple_sampler') {
        return device;
      }
    }
    return null;
  }

  DeviceSnapshot? get oscillatorDevice {
    for (final device in visibleDevices) {
      if (device.type == 'simple_oscillator') {
        return device;
      }
    }
    return null;
  }

  DeviceSnapshot? get subtractiveSynthDevice {
    for (final device in visibleDevices) {
      if (device.type == 'subtractive_synth') {
        return device;
      }
    }
    return null;
  }

  DeviceSnapshot? get trackGainDevice {
    for (var i = devices.length - 1; i >= 0; i--) {
      if (devices[i].type == 'track_gain') {
        return devices[i];
      }
    }
    return null;
  }
}

class MasterTrackSnapshot {
  const MasterTrackSnapshot({
    required this.id,
    required this.name,
    required this.gain,
  });

  final String id;
  final String name;
  final double gain;

  factory MasterTrackSnapshot.fromMap(Map<dynamic, dynamic>? map) {
    return MasterTrackSnapshot(
      id: map?['id'] as String? ?? 'master',
      name: map?['name'] as String? ?? 'Master',
      gain: (map?['gain'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class TrackSnapshot {
  const TrackSnapshot({
    required this.id,
    required this.name,
    required this.devices,
    required this.midiClips,
    required this.sampleClips,
  });

  final String id;
  final String name;
  final List<DeviceSnapshot> devices;
  final List<MidiClipSnapshot> midiClips;
  final List<SampleClipSnapshot> sampleClips;

  factory TrackSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final devicesRaw = map['devices'] as List<dynamic>? ?? [];
    final clipsRaw = map['midiClips'] as List<dynamic>? ?? [];
    final sampleClipsRaw = map['sampleClips'] as List<dynamic>? ?? [];
    return TrackSnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      devices: devicesRaw
          .map((d) => DeviceSnapshot.fromMap(d as Map<dynamic, dynamic>))
          .toList(),
      midiClips: clipsRaw
          .map((c) => MidiClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
          .toList(),
      sampleClips: sampleClipsRaw
          .map((c) => SampleClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}

class DeviceSnapshot {
  const DeviceSnapshot({
    required this.id,
    required this.type,
    required this.frequencyHz,
    required this.gain,
    required this.pan,
    required this.sampleId,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.filterCutoff,
    required this.filterQ,
    required this.filterMode,
    required this.trimStartSec,
    required this.trimEndSec,
    this.bypassed = false,
    this.osc1Wave = 2,
    this.osc2Wave = 2,
    this.osc1Shape = 0.5,
    this.osc2Shape = 0.5,
    this.osc1Octave = 0.5,
    this.osc1Semi = 0.0,
    this.osc1Detune = 0.5,
    this.osc2Octave = 0.5,
    this.osc2Semi = 0.0,
    this.osc2Detune = 0.5,
    this.osc1Level = 0.85,
    this.osc2Level = 0.5,
    this.oscMix = 0.37,
    this.osc1Sync = 0.0,
    this.osc2Sync = 0.0,
    this.noiseLevel = 0.0,
    this.oscMixMode = 0,
    this.unisonVoices = 0.0,
    this.unisonDetune = 0.35,
    this.filterEnvAmount = 0.5,
    this.filterAttack = 0.05,
    this.filterDecay = 0.35,
    this.filterSustain = 0.4,
    this.filterRelease = 0.45,
    this.glideMs = 0.0,
    this.velocitySensitivity = 1.0,
  });

  final String id;
  final String type;
  final double frequencyHz;
  final double gain;
  final double pan;
  final String sampleId;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double filterCutoff;
  final double filterQ;
  final int filterMode;
  final double trimStartSec;
  final double trimEndSec;
  final bool bypassed;
  final int osc1Wave;
  final int osc2Wave;
  final double osc1Shape;
  final double osc2Shape;
  final double osc1Octave;
  final double osc1Semi;
  final double osc1Detune;
  final double osc2Octave;
  final double osc2Semi;
  final double osc2Detune;
  final double osc1Level;
  final double osc2Level;
  final double oscMix;
  final double osc1Sync;
  final double osc2Sync;
  final double noiseLevel;
  final int oscMixMode;
  final double unisonVoices;
  final double unisonDetune;
  final double filterEnvAmount;
  final double filterAttack;
  final double filterDecay;
  final double filterSustain;
  final double filterRelease;
  final double glideMs;
  final double velocitySensitivity;

  factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    return DeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      frequencyHz: (params['frequency'] as num?)?.toDouble() ?? 440.0,
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      sampleId: params['sampleId'] as String? ?? '',
      attack: (params['attack'] as num?)?.toDouble() ?? 0.01,
      decay: (params['decay'] as num?)?.toDouble() ?? 0.3,
      sustain: (params['sustain'] as num?)?.toDouble() ?? 0.7,
      release: (params['release'] as num?)?.toDouble() ?? 0.4,
      filterCutoff: (params['filterCutoff'] as num?)?.toDouble() ?? 1.0,
      filterQ: (params['filterQ'] as num?)?.toDouble() ?? 0.35,
      filterMode: (params['filterMode'] as num?)?.toInt() ?? 0,
      trimStartSec: (params['trimStartSec'] as num?)?.toDouble() ?? 0.0,
      trimEndSec: (params['trimEndSec'] as num?)?.toDouble() ?? 0.0,
      bypassed: _readBypass(params['bypass']),
      osc1Wave: (params['osc1Wave'] as num?)?.toInt() ?? 2,
      osc2Wave: (params['osc2Wave'] as num?)?.toInt() ?? 2,
      osc1Shape: (params['osc1Shape'] as num?)?.toDouble() ??
          ((params['osc1Wave'] as num?)?.toInt() ?? 2) / 4.0,
      osc2Shape: (params['osc2Shape'] as num?)?.toDouble() ??
          ((params['osc2Wave'] as num?)?.toInt() ?? 2) / 4.0,
      osc1Octave: (params['osc1Octave'] as num?)?.toDouble() ?? 0.5,
      osc1Semi: (params['osc1Semi'] as num?)?.toDouble() ?? 0.0,
      osc1Detune: (params['osc1Detune'] as num?)?.toDouble() ?? 0.5,
      osc2Octave: (params['osc2Octave'] as num?)?.toDouble() ?? 0.5,
      osc2Semi: (params['osc2Semi'] as num?)?.toDouble() ?? 0.0,
      osc2Detune: (params['osc2Detune'] as num?)?.toDouble() ?? 0.5,
      osc1Level: (params['osc1Level'] as num?)?.toDouble() ?? 0.85,
      osc2Level: (params['osc2Level'] as num?)?.toDouble() ?? 0.5,
      oscMix: (params['oscMix'] as num?)?.toDouble() ??
          _deriveOscMix(
            (params['osc1Level'] as num?)?.toDouble() ?? 0.85,
            (params['osc2Level'] as num?)?.toDouble() ?? 0.5,
          ),
      osc1Sync: (params['osc1Sync'] as num?)?.toDouble() ?? 0.0,
      osc2Sync: (params['osc2Sync'] as num?)?.toDouble() ?? 0.0,
      noiseLevel: (params['noiseLevel'] as num?)?.toDouble() ?? 0.0,
      oscMixMode: (params['oscMixMode'] as num?)?.toInt() ?? 0,
      unisonVoices: (params['unisonVoices'] as num?)?.toDouble() ?? 0.0,
      unisonDetune: (params['unisonDetune'] as num?)?.toDouble() ?? 0.35,
      filterEnvAmount: (params['filterEnvAmount'] as num?)?.toDouble() ?? 0.5,
      filterAttack: (params['filterAttack'] as num?)?.toDouble() ?? 0.05,
      filterDecay: (params['filterDecay'] as num?)?.toDouble() ?? 0.35,
      filterSustain: (params['filterSustain'] as num?)?.toDouble() ?? 0.4,
      filterRelease: (params['filterRelease'] as num?)?.toDouble() ?? 0.45,
      glideMs: (params['glideMs'] as num?)?.toDouble() ?? 0.0,
      velocitySensitivity: (params['velocitySensitivity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static double _deriveOscMix(double osc1Level, double osc2Level) {
    final sum = osc1Level + osc2Level;
    if (sum <= 0.001) return 0.37;
    return osc2Level / sum;
  }

  static bool _readBypass(dynamic value) {
    return switch (value) {
      true => true,
      false => false,
      final num n => n != 0,
      _ => false,
    };
  }

  DeviceSnapshot copyWith({
    String? id,
    String? type,
    double? frequencyHz,
    double? gain,
    double? pan,
    String? sampleId,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    double? filterCutoff,
    double? filterQ,
    int? filterMode,
    double? trimStartSec,
    double? trimEndSec,
    bool? bypassed,
    int? osc1Wave,
    int? osc2Wave,
    double? osc1Shape,
    double? osc2Shape,
    double? osc1Octave,
    double? osc1Semi,
    double? osc1Detune,
    double? osc2Octave,
    double? osc2Semi,
    double? osc2Detune,
    double? osc1Level,
    double? osc2Level,
    double? oscMix,
    double? osc1Sync,
    double? osc2Sync,
    double? noiseLevel,
    int? oscMixMode,
    double? unisonVoices,
    double? unisonDetune,
    double? filterEnvAmount,
    double? filterAttack,
    double? filterDecay,
    double? filterSustain,
    double? filterRelease,
    double? glideMs,
    double? velocitySensitivity,
  }) {
    return DeviceSnapshot(
      id: id ?? this.id,
      type: type ?? this.type,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      sampleId: sampleId ?? this.sampleId,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      filterCutoff: filterCutoff ?? this.filterCutoff,
      filterQ: filterQ ?? this.filterQ,
      filterMode: filterMode ?? this.filterMode,
      trimStartSec: trimStartSec ?? this.trimStartSec,
      trimEndSec: trimEndSec ?? this.trimEndSec,
      bypassed: bypassed ?? this.bypassed,
      osc1Wave: osc1Wave ?? this.osc1Wave,
      osc2Wave: osc2Wave ?? this.osc2Wave,
      osc1Shape: osc1Shape ?? this.osc1Shape,
      osc2Shape: osc2Shape ?? this.osc2Shape,
      osc1Octave: osc1Octave ?? this.osc1Octave,
      osc1Semi: osc1Semi ?? this.osc1Semi,
      osc1Detune: osc1Detune ?? this.osc1Detune,
      osc2Octave: osc2Octave ?? this.osc2Octave,
      osc2Semi: osc2Semi ?? this.osc2Semi,
      osc2Detune: osc2Detune ?? this.osc2Detune,
      osc1Level: osc1Level ?? this.osc1Level,
      osc2Level: osc2Level ?? this.osc2Level,
      oscMix: oscMix ?? this.oscMix,
      osc1Sync: osc1Sync ?? this.osc1Sync,
      osc2Sync: osc2Sync ?? this.osc2Sync,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      oscMixMode: oscMixMode ?? this.oscMixMode,
      unisonVoices: unisonVoices ?? this.unisonVoices,
      unisonDetune: unisonDetune ?? this.unisonDetune,
      filterEnvAmount: filterEnvAmount ?? this.filterEnvAmount,
      filterAttack: filterAttack ?? this.filterAttack,
      filterDecay: filterDecay ?? this.filterDecay,
      filterSustain: filterSustain ?? this.filterSustain,
      filterRelease: filterRelease ?? this.filterRelease,
      glideMs: glideMs ?? this.glideMs,
      velocitySensitivity: velocitySensitivity ?? this.velocitySensitivity,
    );
  }

  DeviceSnapshot withParameter(String parameterId, double value) {
    switch (parameterId) {
      case 'attack':
        return copyWith(attack: value);
      case 'decay':
        return copyWith(decay: value);
      case 'sustain':
        return copyWith(sustain: value);
      case 'release':
        return copyWith(release: value);
      case 'gain':
        return copyWith(gain: value);
      case 'pan':
        return copyWith(pan: value);
      case 'filterCutoff':
        return copyWith(filterCutoff: value);
      case 'filterQ':
        return copyWith(filterQ: value);
      case 'filterMode':
        return copyWith(filterMode: value.round().clamp(0, 3));
      case 'trimStartSec':
        return copyWith(trimStartSec: value);
      case 'trimEndSec':
        return copyWith(trimEndSec: value);
      case 'bypass':
        return copyWith(bypassed: value >= 0.5);
      case 'osc1Wave':
        return copyWith(
          osc1Wave: value.round().clamp(0, 4),
          osc1Shape: value.round().clamp(0, 4) / 4.0,
        );
      case 'osc2Wave':
        return copyWith(
          osc2Wave: value.round().clamp(0, 4),
          osc2Shape: value.round().clamp(0, 4) / 4.0,
        );
      case 'osc1Shape':
        return copyWith(
          osc1Shape: value.clamp(0.0, 1.0),
          osc1Wave: (value * 4).round().clamp(0, 4),
        );
      case 'osc2Shape':
        return copyWith(
          osc2Shape: value.clamp(0.0, 1.0),
          osc2Wave: (value * 4).round().clamp(0, 4),
        );
      case 'osc1Octave':
        return copyWith(osc1Octave: value);
      case 'osc1Semi':
        return copyWith(osc1Semi: value);
      case 'osc1Detune':
        return copyWith(osc1Detune: value);
      case 'osc2Octave':
        return copyWith(osc2Octave: value);
      case 'osc2Semi':
        return copyWith(osc2Semi: value);
      case 'osc2Detune':
        return copyWith(osc2Detune: value);
      case 'osc1Level':
        return copyWith(osc1Level: value);
      case 'osc2Level':
        return copyWith(osc2Level: value);
      case 'oscMix':
        return copyWith(oscMix: value.clamp(0.0, 1.0));
      case 'osc1Sync':
        return copyWith(osc1Sync: value.clamp(0.0, 1.0));
      case 'osc2Sync':
        return copyWith(osc2Sync: value.clamp(0.0, 1.0));
      case 'noiseLevel':
        return copyWith(noiseLevel: value);
      case 'oscMixMode':
        return copyWith(oscMixMode: value.round().clamp(0, 4));
      case 'unisonVoices':
        return copyWith(unisonVoices: value);
      case 'unisonDetune':
        return copyWith(unisonDetune: value);
      case 'filterEnvAmount':
        return copyWith(filterEnvAmount: value);
      case 'filterAttack':
        return copyWith(filterAttack: value);
      case 'filterDecay':
        return copyWith(filterDecay: value);
      case 'filterSustain':
        return copyWith(filterSustain: value);
      case 'filterRelease':
        return copyWith(filterRelease: value);
      case 'glideMs':
        return copyWith(glideMs: value);
      case 'velocitySensitivity':
        return copyWith(velocitySensitivity: value);
      default:
        return this;
    }
  }
}

class SampleLibraryEntrySnapshot {
  const SampleLibraryEntrySnapshot({
    required this.id,
    required this.name,
    required this.source,
    required this.durationBeats,
    required this.waveformPeaks,
  });

  final String id;
  final String name;
  final String source;
  final double durationBeats;
  final List<double> waveformPeaks;

  factory SampleLibraryEntrySnapshot.fromMap(Map<dynamic, dynamic> map) {
    final peaksRaw = map['waveformPeaks'] as List<dynamic>? ?? [];
    return SampleLibraryEntrySnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      source: map['source'] as String? ?? '',
      durationBeats: (map['durationBeats'] as num?)?.toDouble() ?? 4.0,
      waveformPeaks: peaksRaw.map((p) => (p as num).toDouble()).toList(),
    );
  }
}

/// LFO source snapshot from the engine.
class LfoSnapshot {
  const LfoSnapshot({
    required this.id,
    this.waveform = 0,
    this.rate = 1.0,
    this.syncDivision = 0,
    this.phase = 0.0,
    this.name = '',
  });

  final int id;
  final int waveform; // 0=Sine, 1=Tri, 2=Saw, 3=Square, 4=Ramp
  final double rate;
  final int syncDivision; // 0=free, 1=1/1, 2=1/2, 3=1/4, 4=1/8, 5=1/16
  final double phase;
  final String name;

  factory LfoSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return LfoSnapshot(
      id: (map['id'] as num?)?.toInt() ?? 0,
      waveform: (map['waveform'] as num?)?.toInt() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 1.0,
      syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 0,
      phase: (map['phase'] as num?)?.toDouble() ?? 0.0,
      name: map['name'] as String? ?? '',
    );
  }

  static const List<String> waveformNames = [
    'Sine', 'Tri', 'Saw', 'Square', 'Ramp',
  ];

  String get waveformName => waveform >= 0 && waveform < waveformNames.length
      ? waveformNames[waveform]
      : 'Sine';

  LfoSnapshot copyWith({
    int? id,
    int? waveform,
    double? rate,
    int? syncDivision,
    double? phase,
    String? name,
  }) {
    return LfoSnapshot(
      id: id ?? this.id,
      waveform: waveform ?? this.waveform,
      rate: rate ?? this.rate,
      syncDivision: syncDivision ?? this.syncDivision,
      phase: phase ?? this.phase,
      name: name ?? this.name,
    );
  }
}

/// Modulation edge linking an LFO to a device parameter.
class ModulationEdgeSnapshot {
  const ModulationEdgeSnapshot({
    required this.lfoId,
    required this.deviceId,
    required this.paramId,
    this.amount = 0.0,
  });

  final int lfoId;
  final String deviceId;
  final String paramId;
  final double amount;

  factory ModulationEdgeSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return ModulationEdgeSnapshot(
      lfoId: (map['lfoId'] as num?)?.toInt() ?? 0,
      deviceId: map['deviceId'] as String? ?? '',
      paramId: map['paramId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ModulationEdgeSnapshot copyWith({
    int? lfoId,
    String? deviceId,
    String? paramId,
    double? amount,
  }) {
    return ModulationEdgeSnapshot(
      lfoId: lfoId ?? this.lfoId,
      deviceId: deviceId ?? this.deviceId,
      paramId: paramId ?? this.paramId,
      amount: amount ?? this.amount,
    );
  }
}
