part of 'automation_curve_shapes.dart';

extension AutomationCurveShapeLabels on AutomationCurveShape {
  String get label => switch (this) {
        AutomationCurveShape.rampUp => 'Ramp ↑',
        AutomationCurveShape.rampDown => 'Ramp ↓',
        AutomationCurveShape.sawUp => 'Saw ↑',
        AutomationCurveShape.sawDown => 'Saw ↓',
        AutomationCurveShape.triangle => 'Triangle',
        AutomationCurveShape.square => 'Square',
        AutomationCurveShape.sine => 'Sine',
      };

  bool get isPeriodic => switch (this) {
        AutomationCurveShape.rampUp || AutomationCurveShape.rampDown => false,
        _ => true,
      };

  bool get usesDuty => this == AutomationCurveShape.square;
}
