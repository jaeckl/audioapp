part of 'automation_curve_shapes.dart';

List<AutomationPointSnapshot> paintRepeatedAutomationShape({
  required List<AutomationPointSnapshot> points,
  required double startBeat,
  required double endBeat,
  required double stepBeats,
  required double baseline,
  required double peak,
  required AutomationCurveShape shape,
  double valueMin = 0,
  double valueMax = 1,
}) {
  final left = math.min(startBeat, endBeat);
  final right = math.max(startBeat, endBeat);
  if (right - left <= 1.0e-6 || stepBeats <= 0) {
    return List<AutomationPointSnapshot>.of(points);
  }

  final generated = <AutomationPointSnapshot>[];
  var cellStart = left;
  while (cellStart < right - 1.0e-6) {
    final cellEnd = math.min(cellStart + stepBeats, right);
    final local = generateAutomationShapePoints(
      shape: shape,
      params: const AutomationShapeParams(min: 0, max: 1),
      lengthBeats: cellEnd - cellStart,
    );
    for (final point in local) {
      final normalized = point.value.clamp(0.0, 1.0);
      generated.add(AutomationPointSnapshot(
        beat: cellStart + point.beat,
        value: (baseline + (peak - baseline) * normalized).clamp(valueMin, valueMax),
      ));
    }
    cellStart = cellEnd;
  }

  final kept = points.where(
    (point) => point.beat < left - 1.0e-4 || point.beat > right + 1.0e-4,
  );
  return _dedupePoints([...kept, ...generated]);
}
