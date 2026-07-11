part of 'automation_curve_shapes.dart';

List<AutomationPointSnapshot> _generateSine(
  AutomationShapeParams params,
  double lengthBeats,
  int segmentsPerCycle,
) {
  final min = params.clampedMin;
  final max = params.clampedMax;
  final cycles = params.clampedCycles;
  final phase = params.clampedPhase;
  final span = max - min;
  final totalSegments = math.max(2, (segmentsPerCycle * cycles).round());

  final points = <AutomationPointSnapshot>[];
  for (var i = 0; i <= totalSegments; i++) {
    final t = i / totalSegments;
    final beat = t * lengthBeats;
    final angle = 2 * math.pi * (t * cycles + phase);
    final value = min + span * (0.5 + 0.5 * math.sin(angle));
    points.add(AutomationPointSnapshot(beat: beat, value: value.clamp(0.0, 1.0)));
  }
  return _dedupePoints(points);
}
