part of 'clip_snapshots.dart';

class SampleClipTakeSnapshot {
  const SampleClipTakeSnapshot({
    required this.id,
    required this.sampleId,
    required this.name,
    required this.startBeatOffset,
    required this.lengthBeats,
  });

  final String id;
  final String sampleId;
  final String name;
  final double startBeatOffset;
  final double lengthBeats;

  factory SampleClipTakeSnapshot.fromMap(Map<dynamic, dynamic> map) =>
      SampleClipTakeSnapshot(
        id: map['id'] as String? ?? '',
        sampleId: map['sampleId'] as String? ?? '',
        name: map['name'] as String? ?? 'Take',
        startBeatOffset: (map['startBeatOffset'] as num?)?.toDouble() ?? 0.0,
        lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 0.0,
      );
}
