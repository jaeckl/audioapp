/// Engine project snapshot from C++.
class ProjectSnapshot {
  const ProjectSnapshot({
    required this.bpm,
    required this.selectedTrackId,
    required this.playheadBeats,
    required this.playing,
    required this.master,
    required this.samples,
    required this.tracks,
  });

  final int bpm;
  final String selectedTrackId;
  final double playheadBeats;
  final bool playing;
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
    );
  }
}

class MidiClipSnapshot {
  const MidiClipSnapshot({
    required this.id,
    required this.startBeat,
    required this.lengthBeats,
    required this.notes,
  });

  final String id;
  final double startBeat;
  final double lengthBeats;
  final List<MidiNoteSnapshot> notes;

  factory MidiClipSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final notesRaw = map['notes'] as List<dynamic>? ?? [];
    return MidiClipSnapshot(
      id: map['id'] as String? ?? '',
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 4.0,
      notes: notesRaw
          .map((n) => MidiNoteSnapshot.fromMap(n as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}

class SampleClipSnapshot {
  const SampleClipSnapshot({
    required this.id,
    required this.sampleId,
    required this.sampleName,
    required this.startBeat,
    required this.lengthBeats,
    required this.waveformPeaks,
  });

  final String id;
  final String sampleId;
  final String sampleName;
  final double startBeat;
  final double lengthBeats;
  final List<double> waveformPeaks;

  factory SampleClipSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final peaksRaw = map['waveformPeaks'] as List<dynamic>? ?? [];
    return SampleClipSnapshot(
      id: map['id'] as String? ?? '',
      sampleId: map['sampleId'] as String? ?? '',
      sampleName: map['sampleName'] as String? ?? '',
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 4.0,
      waveformPeaks: peaksRaw.map((p) => (p as num).toDouble()).toList(),
    );
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

class MidiNoteSnapshot {
  const MidiNoteSnapshot({
    required this.pitch,
    required this.startBeat,
    required this.durationBeats,
    required this.velocity,
  });

  final int pitch;
  final double startBeat;
  final double durationBeats;
  final double velocity;

  factory MidiNoteSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return MidiNoteSnapshot(
      pitch: (map['pitch'] as num?)?.toInt() ?? 60,
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      durationBeats: (map['durationBeats'] as num?)?.toDouble() ?? 1.0,
      velocity: (map['velocity'] as num?)?.toDouble() ?? 100.0,
    );
  }
}
