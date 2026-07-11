part of 'project_snapshot.dart';

class TrackFreezeSnapshot {
  const TrackFreezeSnapshot({
    this.enabled = false,
    this.stale = false,
    this.startBeat = 0.0,
    this.lengthBeats = 0.0,
    this.waveformPeaks = const [],
  });

  final bool enabled;
  final bool stale;
  final double startBeat;
  final double lengthBeats;
  final List<double> waveformPeaks;

  factory TrackFreezeSnapshot.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const TrackFreezeSnapshot();
    }
    final peaksRaw = map['waveformPeaks'] as List<dynamic>? ?? [];
    return TrackFreezeSnapshot(
      enabled: map['enabled'] == true,
      stale: map['stale'] == true,
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 0.0,
      waveformPeaks: peaksRaw.map((p) => (p as num).toDouble()).toList(),
    );
  }
}
