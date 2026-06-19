import 'package:audioapp/features/automation/automation_curve_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('saw shape with multiple cycles produces more than default two points', () {
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
