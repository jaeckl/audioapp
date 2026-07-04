import '../bridge/clip_snapshots.dart';

class AutomationRecordedPoint {
  const AutomationRecordedPoint(this.beat, this.value);

  final double beat;
  final double value;
}

class AutomationRecordingLane {
  AutomationRecordingLane({
    required this.trackId,
    required this.deviceId,
    required this.paramId,
    required this.startBeat,
  });

  final String trackId;
  final String deviceId;
  final String paramId;
  final double startBeat;
  final List<AutomationRecordedPoint> points = [];
}

class AutomationSegmentCommit {
  const AutomationSegmentCommit({
    required this.trackId,
    required this.deviceId,
    required this.paramId,
    required this.startBeat,
    required this.lengthBeats,
    required this.points,
  });

  final String trackId;
  final String deviceId;
  final String paramId;
  final double startBeat;
  final double lengthBeats;
  final List<AutomationPointSnapshot> points;

  String get laneKey => '$trackId:$deviceId:$paramId';
}

class AutomationRecordingSessionBuffer {
  String? activeTrackId;
  double startBeat = 0.0;
  final Map<String, AutomationRecordingLane> _lanes = {};

  bool get isActive => activeTrackId != null;

  void begin({required String trackId, required double startBeat}) {
    activeTrackId = trackId;
    this.startBeat = startBeat;
    _lanes.clear();
  }

  void cancel() {
    activeTrackId = null;
    _lanes.clear();
  }

  void recordPoint({
    required String trackId,
    required String deviceId,
    required String paramId,
    required double value,
    required double beat,
  }) {
    if (activeTrackId != trackId || beat < startBeat - 0.001) return;
    final lane = _lanes.putIfAbsent(
      '$trackId:$deviceId:$paramId',
      () => AutomationRecordingLane(
        trackId: trackId,
        deviceId: deviceId,
        paramId: paramId,
        startBeat: startBeat,
      ),
    );
    final clampedValue = value.clamp(0.0, 1.0).toDouble();
    final last = lane.points.isEmpty ? null : lane.points.last;
    if (last != null &&
        (beat - last.beat).abs() < 0.03 &&
        (clampedValue - last.value).abs() < 0.003) {
      return;
    }
    lane.points.add(AutomationRecordedPoint(beat, clampedValue));
  }

  List<AutomationSegmentCommit> finishSegment({
    required double endBeat,
    required bool keepActive,
    double? nextStartBeat,
  }) {
    if (!isActive) return const [];
    final trackId = activeTrackId;
    final lanes = List<AutomationRecordingLane>.of(_lanes.values);
    _lanes.clear();
    if (keepActive && trackId != null) {
      activeTrackId = trackId;
      startBeat = nextStartBeat ?? endBeat;
    } else {
      activeTrackId = null;
    }

    return [
      for (final lane in lanes)
        if (_commitForLane(lane, endBeat, provisional: false)
            case final commit?)
          commit,
    ];
  }

  List<AutomationSegmentCommit> previewSegments({required double endBeat}) {
    if (!isActive) return const [];
    return [
      for (final lane in _lanes.values)
        if (_commitForLane(lane, endBeat, provisional: true) case final commit?)
          commit,
    ];
  }

  AutomationSegmentCommit? _commitForLane(
    AutomationRecordingLane lane,
    double endBeat, {
    required bool provisional,
  }) {
    final lengthBeats = (endBeat - lane.startBeat).clamp(0.25, 1024.0);
    final sorted = lane.points
        .where((point) =>
            point.beat >= lane.startBeat - 0.001 &&
            point.beat <= endBeat + 0.001)
        .toList()
      ..sort((a, b) => a.beat.compareTo(b.beat));
    if (sorted.isEmpty || (!provisional && sorted.length < 2)) return null;

    var minValue = sorted.first.value;
    var maxValue = sorted.first.value;
    for (final point in sorted.skip(1)) {
      minValue = point.value < minValue ? point.value : minValue;
      maxValue = point.value > maxValue ? point.value : maxValue;
    }
    if (!provisional && (maxValue - minValue).abs() < 0.003) return null;

    final points = <AutomationPointSnapshot>[
      AutomationPointSnapshot(beat: 0, value: sorted.first.value),
      for (final point in sorted)
        AutomationPointSnapshot(
          beat: (point.beat - lane.startBeat).clamp(0.0, lengthBeats),
          value: point.value,
        ),
      AutomationPointSnapshot(beat: lengthBeats, value: sorted.last.value),
    ];

    return AutomationSegmentCommit(
      trackId: lane.trackId,
      deviceId: lane.deviceId,
      paramId: lane.paramId,
      startBeat: lane.startBeat,
      lengthBeats: lengthBeats.toDouble(),
      points: _dedupePoints(points),
    );
  }

  List<AutomationPointSnapshot> _dedupePoints(
    List<AutomationPointSnapshot> points,
  ) {
    final deduped = <AutomationPointSnapshot>[];
    for (final point in points) {
      final last = deduped.isEmpty ? null : deduped.last;
      if (last != null &&
          (point.beat - last.beat).abs() < 0.0001 &&
          (point.value - last.value).abs() < 0.0001) {
        continue;
      }
      deduped.add(point);
    }
    return deduped;
  }
}
