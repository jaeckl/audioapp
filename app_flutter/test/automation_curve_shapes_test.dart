import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/automation/automation_curve_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shape paint repeats once per grid segment and replaces its region', () {
    const points = [
      AutomationPointSnapshot(beat: 0, value: 0.2),
      AutomationPointSnapshot(beat: 4, value: 0.8),
    ];

    final result = paintRepeatedAutomationShape(
      points: points,
      startBeat: 1,
      endBeat: 2,
      stepBeats: 0.25,
      baseline: 0.25,
      peak: 0.75,
      shape: AutomationCurveShape.triangle,
    );

    expect(result.first, points.first);
    expect(result.last, points.last);
    expect(result.where((point) => point.beat >= 1 && point.beat <= 2).length,
        greaterThanOrEqualTo(8));
    expect(result.any((point) => (point.value - 0.75).abs() < 1e-6), isTrue);
  });

  test('downward shape drag inverts amplitude', () {
    final result = paintRepeatedAutomationShape(
      points: const [],
      startBeat: 0,
      endBeat: 1,
      stepBeats: 1,
      baseline: 0.8,
      peak: 0.2,
      shape: AutomationCurveShape.rampUp,
    );

    expect(result.first.value, closeTo(0.8, 1e-6));
    expect(result.last.value, closeTo(0.2, 1e-6));
  });
  test('saw shape with multiple cycles produces more than default two points',
      () {
    final points = generateAutomationShapePoints(
      shape: AutomationCurveShape.sawUp,
      params: const AutomationShapeParams(cycles: 4),
      lengthBeats: 4,
    );
    expect(points.length, greaterThan(2));
    expect(points.first.beat, 0);
    expect(points.last.beat, lessThanOrEqualTo(4));
  });
}
