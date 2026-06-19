import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static waveform preview — morphs continuously with [shape] 0..1.
class SubtractiveWaveformPreview extends StatelessWidget {
  const SubtractiveWaveformPreview({
    super.key,
    required this.shape,
    required this.accent,
    this.height = 52,
    this.showLabel = true,
  });

  final double shape;
  final Color accent;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : height;
        final resolvedWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : double.infinity;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: Size(resolvedWidth, resolvedHeight),
                painter: _WavePainter(shape: shape, color: accent),
              ),
              if (showLabel)
                Positioned(
                  left: 6,
                  top: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      child: Text(
                        subtractiveShapeLabel(shape),
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.95),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.shape, required this.color});

  final double shape;
  final Color color;

  static const _samples = 140;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height * 0.5;
    final amp = size.height * 0.36;

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), grid);
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }

    final path = Path();
    for (var i = 0; i <= _samples; i++) {
      final t = i / _samples;
      final phase = t * math.pi * 2;
      final y = midY - _morphSample(shape, phase) * amp;
      final x = 4 + t * (size.width - 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fill = Path.from(path)
      ..lineTo(size.width - 4, midY)
      ..lineTo(4, midY)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  double _morphSample(double shape, double phase) {
    final scaled = shape.clamp(0.0, 1.0) * 4.0;
    final i0 = scaled.floor().clamp(0, 4);
    final i1 = (i0 + 1).clamp(0, 4);
    final t = scaled - i0;
    final a = _discreteSample(i0, phase);
    final b = _discreteSample(i1, phase);
    return a * (1.0 - t) + b * t;
  }

  double _discreteSample(int wave, double phase) {
    return switch (wave) {
      0 => math.sin(phase),
      1 => phase <= math.pi ? (2 * phase / math.pi - 1) : (3 - 2 * phase / math.pi),
      2 => (2 / math.pi) * (phase - math.pi),
      3 => phase < math.pi ? 1.0 : -1.0,
      _ => phase < math.pi ? 1.0 : -0.2,
    };
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.shape != shape || oldDelegate.color != color;
}

String subtractiveShapeLabel(double shape) {
  const names = ['Sine', 'Tri', 'Saw', 'Sqr', 'Pls'];
  return names[(shape * 4).round().clamp(0, 4)];
}
