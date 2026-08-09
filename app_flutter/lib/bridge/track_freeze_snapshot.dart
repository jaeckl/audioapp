part of 'project_snapshot.dart';

/// Mirrors engine `TrackFreezeMode`: 0 Off, 1 Auto, 2 Manual.
class TrackFreezeSnapshot {
  const TrackFreezeSnapshot({
    this.enabled = false,
    this.stale = false,
    this.mode = 0,
    this.startBeat = 0.0,
    this.lengthBeats = 0.0,
    this.bakeEndDeviceIndex = 0,
    this.waveformPeaks = const [],
  });

  final bool enabled;
  final bool stale;
  final int mode;
  final double startBeat;
  final double lengthBeats;

  /// Exclusive flattened playback index of the bake split (engine space).
  /// Slots `[0, bakeEndDeviceIndex)` are baked; the rest stay live.
  final int bakeEndDeviceIndex;
  final List<double> waveformPeaks;

  bool get isAuto => mode == 1;
  bool get isManual => mode == 2 || (enabled && mode == 0);

  /// User-visible freeze chrome (badge / freeze clip) — never for Auto cache.
  bool get showFreezeChrome => enabled && !isAuto;

  factory TrackFreezeSnapshot.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const TrackFreezeSnapshot();
    }
    final peaksRaw = map['waveformPeaks'] as List<dynamic>? ?? [];
    final enabled = map['enabled'] == true;
    final mode = (map['mode'] as num?)?.toInt() ?? (enabled ? 2 : 0);
    return TrackFreezeSnapshot(
      enabled: enabled,
      stale: map['stale'] == true,
      mode: mode,
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 0.0,
      bakeEndDeviceIndex: (map['bakeEndDeviceIndex'] as num?)?.toInt() ?? 0,
      waveformPeaks: peaksRaw.map((p) => (p as num).toDouble()).toList(),
    );
  }
}
