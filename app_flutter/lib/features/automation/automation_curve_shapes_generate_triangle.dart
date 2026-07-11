part of 'automation_curve_shapes.dart';

List<AutomationPointSnapshot> _generateTriangle(
  AutomationShapeParams params,
  double lengthBeats,
) {
  final min = params.clampedMin;
  final max = params.clampedMax;
  final cycles = params.clampedCycles;
  final phase = params.clampedPhase;
  final cycleLen = lengthBeats / cycles;

  final points = <AutomationPointSnapshot>[];
  final cycleCount = cycles.ceil();
  for (var c = 0; c < cycleCount; c++) {
    final base = c * cycleLen;
    if (base > lengthBeats) break;

    final phaseShift = phase * cycleLen;
    final b0 = _clampBeat(base - phaseShift, lengthBeats);
    final bPeak = _clampBeat(base + cycleLen * 0.5 - phaseShift, lengthBeats);
    final bEnd = _clampBeat(base + cycleLen - phaseShift, lengthBeats);

    points.add(AutomationPointSnapshot(beat: b0, value: min));
    if (bPeak > b0 && bPeak < lengthBeats) {
      points.add(AutomationPointSnapshot(beat: bPeak, value: max));
    }
    if (bEnd > b0 && bEnd <= lengthBeats) {
      points.add(AutomationPointSnapshot(beat: bEnd, value: min));
    }
  }

  if (points.isEmpty) {
    points.add(AutomationPointSnapshot(beat: 0, value: min));
  }
  points.sort((a, b) => a.beat.compareTo(b.beat));
  return _dedupePoints(points);
}
