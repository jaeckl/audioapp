part of 'automation_curve_shapes.dart';

List<AutomationPointSnapshot> _generateSquare(
  AutomationShapeParams params,
  double lengthBeats,
) {
  final min = params.clampedMin;
  final max = params.clampedMax;
  final cycles = params.clampedCycles;
  final phase = params.clampedPhase;
  final duty = params.clampedDuty;
  final cycleLen = lengthBeats / cycles;

  const edgeEpsilon = 1.0e-4;
  final points = <AutomationPointSnapshot>[];
  final cycleCount = cycles.ceil();

  for (var c = 0; c < cycleCount; c++) {
    final base = c * cycleLen - phase * cycleLen;
    final highEnd = base + cycleLen * duty;
    final cycleEnd = base + cycleLen;

    final edges = [
      (base, max),
      (highEnd - edgeEpsilon, max),
      (highEnd, min),
      (cycleEnd - edgeEpsilon, min),
    ];

    for (final (beat, value) in edges) {
      final clamped = _clampBeat(beat, lengthBeats);
      if (clamped >= 0 && clamped <= lengthBeats) {
        points.add(AutomationPointSnapshot(beat: clamped, value: value));
      }
    }
  }

  points.sort((a, b) => a.beat.compareTo(b.beat));
  return _dedupePoints(points);
}
