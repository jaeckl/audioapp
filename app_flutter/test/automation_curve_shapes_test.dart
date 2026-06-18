import 'package:audioapp/features/automation/automation_curve_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const params = AutomationShapeParams(min: 0.2, max: 0.9, cycles: 2.0);

  test('ramp up spans clip endpoints', () {
    final points = generateAutomationShapePoints(
      shape: AutomationCurveShape.rampUp,
      params: params,
      lengthBeats: 4.0,
    );
    expect(points.first.beat, 0);
    expect(points.first.value, closeTo(0.2, 0.001));
    expect(points.last.beat, 4.0);
    expect(points.last.value, closeTo(0.9, 0.001));
  });

  test('triangle produces peaks per cycle', () {
    final points = generateAutomationShapePoints(
      shape: AutomationCurveShape.triangle,
      params: params,
      lengthBeats: 4.0,
    );
    expect(points.length, greaterThanOrEqualTo(3));
    final peaks = points.where((p) => p.value > 0.85).toList();
    expect(peaks.length, greaterThanOrEqualTo(1));
  });

  test('square alternates min and max', () {
    final points = generateAutomationShapePoints(
      shape: AutomationCurveShape.square,
      params: params.copyWith(cycles: 1.0, duty: 0.5),
      lengthBeats: 4.0,
    );
    expect(points.any((p) => p.value > 0.85), isTrue);
    expect(points.any((p) => p.value < 0.25), isTrue);
  });

  test('saw up rises then resets per cycle', () {
    final points = generateAutomationShapePoints(
      shape: AutomationCurveShape.sawUp,
      params: params.copyWith(cycles: 2.0),
      lengthBeats: 4.0,
    );
    expect(points.any((p) => p.value > 0.85), isTrue);
    expect(points.any((p) => p.value < 0.25), isTrue);
    expect(points.first.beat, 0);
  });

  test('sine stays within min/max', () {
    final points = generateAutomationShapePoints(
      shape: AutomationCurveShape.sine,
      params: params,
      lengthBeats: 4.0,
    );
    for (final p in points) {
      expect(p.value, inInclusiveRange(0.2, 0.9));
    }
    expect(points.first.beat, 0);
    expect(points.last.beat, 4.0);
  });
}
