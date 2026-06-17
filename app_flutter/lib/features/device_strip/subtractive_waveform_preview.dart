import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static waveform preview — morphs continuously with [shape] 0..1.
class SubtractiveWaveformPreview extends StatelessWidget {
  const SubtractiveWaveformPreview({
    super.key,
    required this.shape,
    required this.accent,
    this.height = 48,
  });

  final double shape;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : height;
        return SizedBox(
          height: resolvedHeight,
          child: CustomPaint(
            painter: _WavePainter(shape: shape, color: accent),
            size: Size.infinite,
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

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    const samples = 120;
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final phase = t * math.pi * 2;
      final y = size.height * 0.5 - _morphSample(shape, phase) * size.height * 0.38;
      final x = t * size.width;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
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
