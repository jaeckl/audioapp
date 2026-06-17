import 'timeline_clip.dart';

/// MIDI and sample clip snapshots with shared timeline span fields.
class MidiClipSnapshot implements ClipTimelineSpan {
  const MidiClipSnapshot({
    required this.id,
    required this.startBeat,
    required this.lengthBeats,
    required this.notes,
  });

  @override
  final String id;

  @override
  final double startBeat;

  @override
  final double lengthBeats;

  @override
  ClipContentKind get kind => ClipContentKind.midi;

  final List<MidiNoteSnapshot> notes;

  double get endBeat => startBeat + lengthBeats;

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

/// Arrangement clip with sample/audio payload.
class SampleClipSnapshot implements ClipTimelineSpan {
  const SampleClipSnapshot({
    required this.id,
    required this.sampleId,
    required this.sampleName,
    required this.startBeat,
    required this.lengthBeats,
    required this.waveformPeaks,
  });

  @override
  final String id;

  @override
  final double startBeat;

  @override
  final double lengthBeats;

  @override
  ClipContentKind get kind => ClipContentKind.sample;

  final String sampleId;
  final String sampleName;
  final List<double> waveformPeaks;

  double get endBeat => startBeat + lengthBeats;

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
