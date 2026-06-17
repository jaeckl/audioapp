import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device_knob_sizes.dart';

/// Knob dial geometry — 0 at south-west, max at south-east (clockwise over the
/// top; bottom 120° is empty).
abstract final class KnobArcGeometry {
  static const double start = math.pi * (5.0 / 6.0); // 150° — south-west
  static const double sweep = math.pi * (4.0 / 3.0); // +240° clockwise → south-east

  static double indicatorAngle(double value) =>
      start + value.clamp(0.0, 1.0) * sweep;
}

/// Compact rotary control styled after Bitwig / FL Studio Mobile device knobs.
class RotaryKnob extends StatefulWidget {
  const RotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.displayValue,
    this.size = DeviceKnobSizes.strip,
    this.accentColor = const Color(0xFFE8A54B),
    this.modulationActive = false,
    this.onModulationAssign,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? displayValue;
  final double size;
  final Color accentColor;
  final bool modulationActive;
  final VoidCallback? onModulationAssign;

  @override
  State<RotaryKnob> createState() => _RotaryKnobState();
}

class _RotaryKnobState extends State<RotaryKnob> {
  double _dragStartValue = 0;
  double _dragStartY = 0;

  void _onDragStart(DragStartDetails details) {
    _dragStartValue = widget.value;
    _dragStartY = details.localPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final sensitivity = 120.0 + widget.size * 2;
    final delta = (_dragStartY - details.localPosition.dy) / sensitivity;
    widget.onChanged((_dragStartValue + delta).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final stroke = widget.size >= DeviceKnobSizes.editor ? 4.0 : 3.0;
    final theme = Theme.of(context);
    final angle = KnobArcGeometry.indicatorAngle(widget.value);
    final labelSize = widget.size >= DeviceKnobSizes.strip ? 10.0 : 9.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onDoubleTap: () => widget.onChanged(0.5),
          onLongPress: widget.onModulationAssign,
          child: SizedBox(
            width: widget.size + 8,
            height: widget.size + 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _KnobPainter(
                      value: widget.value.clamp(0, 1),
                      angle: angle,
                      accentColor: widget.accentColor,
                      strokeWidth: stroke,
                      modulationActive: widget.modulationActive,
                    ),
                  ),
                ),
                if (widget.displayValue != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.displayValue!,
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: widget.accentColor,
                          fontSize: widget.size * 0.17,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white54,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter({
    required this.value,
    required this.angle,
    required this.accentColor,
    this.strokeWidth = 3,
    this.modulationActive = false,
  });

  final double value;
  final double angle;
  final Color accentColor;
  final double strokeWidth;
  final bool modulationActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      arcRect,
      KnobArcGeometry.start,
      KnobArcGeometry.sweep,
      false,
      trackPaint,
    );

    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      arcRect,
      KnobArcGeometry.start,
      value * KnobArcGeometry.sweep,
      false,
      arcPaint,
    );

    final indicatorPaint = Paint()..color = accentColor;
    final indicatorEnd = Offset(
      center.dx + math.cos(angle) * (radius - 4),
      center.dy + math.sin(angle) * (radius - 4),
    );
    canvas.drawCircle(indicatorEnd, 2.5, indicatorPaint);

    final fillPaint = Paint()..color = const Color(0xFF14141C);
    canvas.drawCircle(center, radius - 6, fillPaint);

    // Modulation indicator dot (top-right of the knob center)
    if (modulationActive) {
      final dotPaint = Paint()..color = accentColor;
      canvas.drawCircle(
        Offset(center.dx + (radius - 6) * 0.5, center.dy - (radius - 6) * 0.5),
        2.0,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.angle != angle ||
        oldDelegate.modulationActive != modulationActive;
  }
}
