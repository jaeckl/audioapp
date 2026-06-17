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

  factory ProjectSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final snapshot = map['snapshot'] as Map<dynamic, dynamic>? ?? map;
    final tracksRaw = snapshot['tracks'] as List<dynamic>? ?? [];
    final samplesRaw = snapshot['samples'] as List<dynamic>? ?? [];
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
  });

  final String id;
  final String type;
  final double frequencyHz;
  final double gain;
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

  factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    return DeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      frequencyHz: (params['frequency'] as num?)?.toDouble() ?? 440.0,
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
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
    );
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
  }) {
    return DeviceSnapshot(
      id: id ?? this.id,
      type: type ?? this.type,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      gain: gain ?? this.gain,
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
