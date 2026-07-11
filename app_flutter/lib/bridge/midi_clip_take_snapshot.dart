part of 'clip_snapshots.dart';

class MidiClipTakeSnapshot {
  const MidiClipTakeSnapshot({
    required this.id,
    required this.name,
    required this.startBeatOffset,
    required this.lengthBeats,
    required this.notes,
  });

  final String id;
  final String name;
  final double startBeatOffset;
  final double lengthBeats;
  final List<MidiNoteSnapshot> notes;

  factory MidiClipTakeSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final notesRaw = map['notes'] as List<dynamic>? ?? [];
    return MidiClipTakeSnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Take',
      startBeatOffset: (map['startBeatOffset'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 0.0,
      notes: notesRaw
          .map((n) => MidiNoteSnapshot.fromMap(n as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}
