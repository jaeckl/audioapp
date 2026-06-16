/// Engine project snapshot from C++.
class ProjectSnapshot {
  const ProjectSnapshot({
    required this.bpm,
    required this.selectedTrackId,
    required this.playheadBeats,
    required this.playing,
    required this.tracks,
  });

  final int bpm;
  final String selectedTrackId;
  final double playheadBeats;
  final bool playing;
  final List<TrackSnapshot> tracks;

  factory ProjectSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final snapshot = map['snapshot'] as Map<dynamic, dynamic>? ?? map;
    final tracksRaw = snapshot['tracks'] as List<dynamic>? ?? [];
    return ProjectSnapshot(
      bpm: (snapshot['bpm'] as num?)?.toInt() ?? 120,
      selectedTrackId: snapshot['selectedTrackId'] as String? ?? '',
      playheadBeats: (snapshot['playheadBeats'] as num?)?.toDouble() ?? 0.0,
      playing: snapshot['playing'] == true,
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

class TrackSnapshot {
  const TrackSnapshot({
    required this.id,
    required this.name,
    required this.devices,
    required this.midiClips,
  });

  final String id;
  final String name;
  final List<DeviceSnapshot> devices;
  final List<MidiClipSnapshot> midiClips;

  factory TrackSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final devicesRaw = map['devices'] as List<dynamic>? ?? [];
    final clipsRaw = map['midiClips'] as List<dynamic>? ?? [];
    return TrackSnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      devices: devicesRaw
          .map((d) => DeviceSnapshot.fromMap(d as Map<dynamic, dynamic>))
          .toList(),
      midiClips: clipsRaw
          .map((c) => MidiClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}

class DeviceSnapshot {
  const DeviceSnapshot({
    required this.id,
    required this.type,
    required this.frequencyHz,
  });

  final String id;
  final String type;
  final double frequencyHz;

  factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    return DeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      frequencyHz: (params['frequency'] as num?)?.toDouble() ?? 440.0,
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
