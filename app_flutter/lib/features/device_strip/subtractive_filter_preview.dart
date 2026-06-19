import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static filter response sketch for the subtractive synth filter tab.
class SubtractiveFilterPreview extends StatelessWidget {
  const SubtractiveFilterPreview({
    super.key,
    required this.filterMode,
    required this.filterCutoff,
    required this.filterQ,
    required this.accent,
  });

  final int filterMode;
  final double filterCutoff;
  final double filterQ;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _FilterResponsePainter(
            filterMode: filterMode,
            filterCutoff: filterCutoff,
            filterQ: filterQ,
            color: accent,
          ),
        );
      },
    );
  }
}

class _FilterResponsePainter extends CustomPainter {
  _FilterResponsePainter({
    required this.filterMode,
    required this.filterCutoff,
    required this.filterQ,
    required this.color,
  });

  final int filterMode;
  final double filterCutoff;
  final double filterQ;
  final Color color;

  static const int _samples = 96;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final path = Path();
    final cutoffX = _cutoffX(size.width);
    final slope = filterMode == 5 ? 2.4 : 1.0;
    final resonance = 0.08 + filterQ.clamp(0.0, 1.0) * 0.22;

    for (var i = 0; i <= _samples; i++) {
      final t = i / _samples;
      final x = t * size.width;
      final mag = _magnitude(t, cutoffX / size.width, slope, resonance);
      final y = size.height * (1.0 - mag * 0.82) - size.height * 0.08;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()..color = color.withValues(alpha: 0.12),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );

    final marker = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(cutoffX, 0),
      Offset(cutoffX, size.height),
      marker,
    );
  }

  double _cutoffX(double width) {
    final clamped = filterCutoff.clamp(0.0, 1.0);
    final logPos = math.log(40 + clamped * 15960) / math.log(16000);
    return (0.08 + logPos * 0.84) * width;
  }

  double _magnitude(double t, double cutoffT, double slope, double resonance) {
    switch (filterMode.clamp(0, 5)) {
      case 1:
        return _highPass(t, cutoffT, slope, resonance);
      case 2:
        return _bandPass(t, cutoffT, resonance);
      case 3:
        return _notch(t, cutoffT, resonance);
      case 4:
        return 0.45 + 0.35 * math.sin(t * math.pi * 10 + cutoffT * 8);
      case 5:
        return _lowPass(t, cutoffT, slope * 1.8, resonance);
      case 0:
      default:
        return _lowPass(t, cutoffT, slope, resonance);
    }
  }

  double _lowPass(double t, double cutoffT, double slope, double resonance) {
    final delta = (t - cutoffT) / 0.08;
    if (delta < 0) {
      final bump = math.exp(-delta * delta * 6.0) * resonance;
      return (1.0 + bump).clamp(0.0, 1.2);
    }
    return math.pow(0.5, delta * slope * 2.2).toDouble().clamp(0.02, 1.0);
  }

  double _highPass(double t, double cutoffT, double slope, double resonance) {
    return _lowPass(1.0 - t, 1.0 - cutoffT, slope, resonance);
  }

  double _bandPass(double t, double cutoffT, double resonance) {
    final width = 0.06 + (1.0 - filterQ.clamp(0.0, 1.0)) * 0.12;
    final dist = (t - cutoffT).abs();
    if (dist > width) {
      return 0.08;
    }
    final norm = 1.0 - dist / width;
    return (0.15 + norm * (0.75 + resonance)).clamp(0.08, 1.0);
  }

  double _notch(double t, double cutoffT, double resonance) {
    final width = 0.05 + (1.0 - filterQ.clamp(0.0, 1.0)) * 0.1;
    final dist = (t - cutoffT).abs();
    if (dist < width) {
      return 0.1 + dist / width * 0.4;
    }
    return 0.9;
  }

  @override
  bool shouldRepaint(covariant _FilterResponsePainter oldDelegate) {
    return oldDelegate.filterMode != filterMode ||
        oldDelegate.filterCutoff != filterCutoff ||
        oldDelegate.filterQ != filterQ ||
        oldDelegate.color != color;
  }
}
