part of 'clip_snapshots.dart';

class SampleClipTakeRegionSnapshot {
  const SampleClipTakeRegionSnapshot({
    required this.startBeat,
    required this.endBeat,
    required this.takeId,
    required this.sourceStart,
  });

  final double startBeat;
  final double endBeat;
  final String takeId;
  final double sourceStart;

  factory SampleClipTakeRegionSnapshot.fromMap(Map<dynamic, dynamic> map) =>
      SampleClipTakeRegionSnapshot(
        startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
        endBeat: (map['endBeat'] as num?)?.toDouble() ?? 0.0,
        takeId: map['takeId'] as String? ?? '',
        sourceStart: (map['sourceStart'] as num?)?.toDouble() ?? 0.0,
      );
}
