part of 'automation_curve_shapes.dart';

List<AutomationPointSnapshot> generateAutomationShapePoints({
  required AutomationCurveShape shape,
  required AutomationShapeParams params,
  required double lengthBeats,
  int sineSegmentsPerCycle = 16,
}) {
  if (lengthBeats <= 0) {
    return const [];
  }

  final min = params.clampedMin;
  final max = params.clampedMax;
  if (min > max) {
    return generateAutomationShapePoints(
      shape: shape,
      params: params.copyWith(min: max, max: min),
      lengthBeats: lengthBeats,
      sineSegmentsPerCycle: sineSegmentsPerCycle,
    );
  }

  switch (shape) {
    case AutomationCurveShape.rampUp:
      return _dedupePoints([
        AutomationPointSnapshot(beat: 0, value: min),
        AutomationPointSnapshot(beat: lengthBeats, value: max),
      ]);
    case AutomationCurveShape.rampDown:
      return _dedupePoints([
        AutomationPointSnapshot(beat: 0, value: max),
        AutomationPointSnapshot(beat: lengthBeats, value: min),
      ]);
    case AutomationCurveShape.sawUp:
      return _generateSaw(params, lengthBeats, rising: true);
    case AutomationCurveShape.sawDown:
      return _generateSaw(params, lengthBeats, rising: false);
    case AutomationCurveShape.triangle:
      return _generateTriangle(params, lengthBeats);
    case AutomationCurveShape.square:
      return _generateSquare(params, lengthBeats);
    case AutomationCurveShape.sine:
      return _generateSine(params, lengthBeats, sineSegmentsPerCycle);
  }
}
