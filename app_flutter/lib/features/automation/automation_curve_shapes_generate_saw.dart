part of 'automation_curve_shapes.dart';

List<AutomationPointSnapshot> _generateSaw(
  AutomationShapeParams params,
  double lengthBeats, {
  required bool rising,
}) {
  final min = params.clampedMin;
  final max = params.clampedMax;
  final cycles = params.clampedCycles;
  final phase = params.clampedPhase;
  final cycleLen = lengthBeats / cycles;

  const edgeEpsilon = 1.0e-4;
  final points = <AutomationPointSnapshot>[];
  final cycleCount = cycles.ceil();

  for (var c = 0; c < cycleCount; c++) {
    final base = c * cycleLen - phase * cycleLen;
    final cycleEnd = base + cycleLen;
    final startValue = rising ? min : max;
    final endValue = rising ? max : min;

    final startBeat = _clampBeat(base, lengthBeats);
    final endBeat = _clampBeat(cycleEnd - edgeEpsilon, lengthBeats);
    final resetBeat = _clampBeat(cycleEnd, lengthBeats);

    if (startBeat <= lengthBeats) {
      points.add(AutomationPointSnapshot(beat: startBeat, value: startValue));
    }
    if (endBeat > startBeat && endBeat <= lengthBeats) {
      points.add(AutomationPointSnapshot(beat: endBeat, value: endValue));
    }
    if (resetBeat > endBeat && resetBeat <= lengthBeats && c < cycleCount - 1) {
      points.add(
        AutomationPointSnapshot(beat: resetBeat, value: startValue),
      );
    }
  }

  if (points.isEmpty) {
    points.add(AutomationPointSnapshot(beat: 0, value: min));
  }
  points.sort((a, b) => a.beat.compareTo(b.beat));
  return _dedupePoints(points);
}
