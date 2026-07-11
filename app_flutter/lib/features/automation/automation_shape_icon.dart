import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'automation_curve_shapes.dart';

part 'automation_shape_icon_automation_shape_icon_painter.dart';

/// Mini waveform glyph for automation shape picker chips.
class AutomationShapeIcon extends StatelessWidget {
  const AutomationShapeIcon({
    super.key,
    required this.shape,
    required this.color,
    this.size = 28,
  });

  final AutomationCurveShape shape;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.55,
      child: CustomPaint(
        painter: _AutomationShapeIconPainter(shape: shape, color: color),
      ),
    );
  }
}

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
