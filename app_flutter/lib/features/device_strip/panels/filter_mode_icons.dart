import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Standard biquad filter modes drawn as magnitude-curve icons.
enum FilterCurveMode {
  lowPass,
  highPass,
  bandPass,
  notch,
}

/// Normalised mode values for the standalone Filter FX device.
abstract final class FilterFxModeNorm {
  static const values = <double>[0.125, 0.375, 0.625, 0.875];
}

class FilterModeIconButton extends StatelessWidget {
  const FilterModeIconButton({
    super.key,
    required this.mode,
    required this.selected,
    required this.onTap,
    this.accentColor = const Color(0xFF5BC0EB),
    this.size = 34,
  });

  final FilterCurveMode mode;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? accentColor : Colors.white.withValues(alpha: 0.38);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        splashColor: accentColor.withValues(alpha: 0.12),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: FilterCurveIconPainter(
              mode: mode,
              color: fg,
              strokeWidth: (size * 0.05).clamp(1.4, 2.2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Magnitude-curve icon painter shared by all filter mode selectors.
class FilterCurveIconPainter extends CustomPainter {
  FilterCurveIconPainter({
    required this.mode,
    required this.color,
    this.strokeWidth = 1.8,
  });

  final FilterCurveMode mode;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 5.0;
    final left = pad;
    final right = size.width - pad;
    final top = pad;
    final bottom = size.height - pad;
    final midX = (left + right) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    switch (mode) {
      case FilterCurveMode.lowPass:
        path.moveTo(left, top + 1);
        path.lineTo(midX - 2, top + 1);
        path.quadraticBezierTo(right - 4, top + 2, right, bottom);
      case FilterCurveMode.highPass:
        path.moveTo(left, bottom);
        path.quadraticBezierTo(left + 4, top + 2, midX + 2, top + 1);
        path.lineTo(right, top + 1);
      case FilterCurveMode.bandPass:
        path.moveTo(left, bottom);
        path.quadraticBezierTo(midX - 6, top, midX, top + 1);
        path.quadraticBezierTo(midX + 6, top, right, bottom);
      case FilterCurveMode.notch:
        path.moveTo(left, top + 1);
        path.lineTo(midX - 7, top + 1);
        path.quadraticBezierTo(midX, bottom - 1, midX + 7, top + 1);
        path.lineTo(right, top + 1);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FilterCurveIconPainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 2×2 grid of filter mode icons (LP/HP top, BP/Notch bottom).
class FilterModeIconGrid extends StatelessWidget {
  const FilterModeIconGrid({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.accentColor = const Color(0xFF5BC0EB),
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        final cellW = (constraints.maxWidth - gap) / 2;
        final cellH = (constraints.maxHeight - gap) / 2;
        final size = math.min(cellW, cellH);

        Widget cell(int index) {
          return Center(
            child: FilterModeIconButton(
              mode: FilterCurveMode.values[index],
              selected: index == selectedIndex,
              accentColor: accentColor,
              size: size,
              onTap: () => onSelected(index),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: cell(0)),
                    const SizedBox(width: gap),
                    Expanded(child: cell(1)),
                  ],
                ),
              ),
              const SizedBox(height: gap),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: cell(2)),
                    const SizedBox(width: gap),
                    Expanded(child: cell(3)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
