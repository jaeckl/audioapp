part of 'automation_curve_shapes.dart';

List<AutomationPointSnapshot> insertAutomationShapeBetween({
  required List<AutomationPointSnapshot> points,
  required double startBeat,
  required double endBeat,
  required double startValue,
  required double endValue,
  required AutomationCurveShape shape,
  required AutomationShapeParams params,
}) {
  final span = endBeat - startBeat;
  if (span <= 1.0e-6) {
    return List<AutomationPointSnapshot>.of(points);
  }

  final segment = generateAutomationShapePoints(
    shape: shape,
    params: params,
    lengthBeats: span,
  );
  if (segment.isEmpty) {
    return List<AutomationPointSnapshot>.of(points);
  }

  final mapped = segment
      .map(
        (p) => AutomationPointSnapshot(
          beat: startBeat + p.beat,
          value: p.value,
        ),
      )
      .toList();
  mapped[0] = AutomationPointSnapshot(beat: startBeat, value: startValue);
  mapped[mapped.length - 1] = AutomationPointSnapshot(beat: endBeat, value: endValue);

  final kept = points.where(
    (p) => p.beat < startBeat - 1.0e-4 || p.beat > endBeat + 1.0e-4,
  );

  return _dedupePoints([...kept, ...mapped]);
}
