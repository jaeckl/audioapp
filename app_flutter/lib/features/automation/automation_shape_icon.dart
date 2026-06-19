import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'automation_curve_shapes.dart';

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

class _AutomationShapeIconPainter extends CustomPainter {
  _AutomationShapeIconPainter({required this.shape, required this.color});

  final AutomationCurveShape shape;
  final Color color;

  static const _inset = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final left = _inset;
    final right = w - _inset;
    final top = _inset;
    final bottom = h - _inset;
    final span = right - left;

    Offset map(double t, double v) {
      return Offset(left + t * span, bottom - v * (bottom - top));
    }

    final path = Path();
    switch (shape) {
      case AutomationCurveShape.rampUp:
        path.moveTo(map(0, 0).dx, map(0, 0).dy);
        path.lineTo(map(1, 1).dx, map(1, 1).dy);
      case AutomationCurveShape.rampDown:
        path.moveTo(map(0, 1).dx, map(0, 1).dy);
        path.lineTo(map(1, 0).dx, map(1, 0).dy);
      case AutomationCurveShape.sawUp:
        _appendSaw(path, map, cycles: 2, rising: true);
      case AutomationCurveShape.sawDown:
        _appendSaw(path, map, cycles: 2, rising: false);
      case AutomationCurveShape.triangle:
        _appendTriangle(path, map, cycles: 2);
      case AutomationCurveShape.square:
        _appendSquare(path, map, cycles: 2, duty: 0.5);
      case AutomationCurveShape.sine:
        _appendSine(path, map, cycles: 2);
    }

    canvas.drawPath(path, paint);
  }

  void _appendSaw(
    Path path,
    Offset Function(double t, double v) map, {
    required int cycles,
    required bool rising,
  }) {
    final steps = cycles * 2;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final cycleT = (t * cycles) % 1.0;
      final v = rising ? cycleT : 1.0 - cycleT;
      final pt = map(t, v);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
  }

  void _appendTriangle(
    Path path,
    Offset Function(double t, double v) map, {
    required int cycles,
  }) {
    final steps = cycles * 2;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final phase = (t * cycles) % 1.0;
      final v = phase < 0.5 ? phase * 2 : (1.0 - phase) * 2;
      final pt = map(t, v);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
  }

  void _appendSquare(
    Path path,
    Offset Function(double t, double v) map, {
    required int cycles,
    required double duty,
  }) {
    const steps = 24;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final phase = (t * cycles) % 1.0;
      final v = phase < duty ? 1.0 : 0.0;
      final pt = map(t, v);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
  }

  void _appendSine(
    Path path,
    Offset Function(double t, double v) map, {
    required int cycles,
  }) {
    const steps = 24;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final angle = 2 * math.pi * t * cycles;
      final v = 0.5 + 0.5 * math.sin(angle);
      final pt = map(t, v);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AutomationShapeIconPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
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
