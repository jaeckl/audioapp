part of 'clip_snapshots.dart';

class MidiClipTakeRegionSnapshot {
  const MidiClipTakeRegionSnapshot({
    required this.startBeat,
    required this.endBeat,
    required this.takeId,
    required this.sourceStart,
    this.holdPrevious = true,
  });

  final double startBeat;
  final double endBeat;
  final String takeId;
  final double sourceStart;

  /// This region's start-boundary handoff: true = ring the previous take's
  /// notes out to their natural length, false = hard cut at the boundary.
  final bool holdPrevious;

  factory MidiClipTakeRegionSnapshot.fromMap(Map<dynamic, dynamic> map) =>
      MidiClipTakeRegionSnapshot(
        startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
        endBeat: (map['endBeat'] as num?)?.toDouble() ?? 0.0,
        takeId: map['takeId'] as String? ?? '',
        sourceStart: (map['sourceStart'] as num?)?.toDouble() ?? 0.0,
        holdPrevious: map['holdPrevious'] as bool? ?? true,
      );
}
