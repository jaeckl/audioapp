part of 'automation_shape_icon.dart';

extension AutomationCurveShapeA11y on AutomationCurveShape {
  String get accessibilityLabel => switch (this) {
        AutomationCurveShape.rampUp => 'Ramp up',
        AutomationCurveShape.rampDown => 'Ramp down',
        AutomationCurveShape.sawUp => 'Saw up',
        AutomationCurveShape.sawDown => 'Saw down',
        AutomationCurveShape.triangle => 'Triangle',
        AutomationCurveShape.square => 'Square',
        AutomationCurveShape.sine => 'Sine',
      };
}
