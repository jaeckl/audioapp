import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Compact rotary control styled after Bitwig device knobs.
class RotaryKnob extends StatefulWidget {
  const RotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.displayValue,
    this.size = 38,
    this.accentColor = const Color(0xFFE8A54B),
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? displayValue;
  final double size;
  final Color accentColor;

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
    final delta = (_dragStartY - details.localPosition.dy) / 120;
    widget.onChanged((_dragStartValue + delta).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final angle = -math.pi * 0.75 + (widget.value.clamp(0, 1) * math.pi * 1.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _KnobPainter(
                value: widget.value.clamp(0, 1),
                angle: angle,
                accentColor: widget.accentColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.displayValue != null)
          SizedBox(
            height: 10,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.displayValue!,
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: widget.accentColor,
                  fontSize: 8,
                ),
              ),
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
  });

  final double value;
  final double angle;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      value * math.pi * 1.5,
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
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.angle != angle;
  }
}
