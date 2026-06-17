import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static waveform preview for subtractive osc tab.
class SubtractiveWaveformPreview extends StatelessWidget {
  const SubtractiveWaveformPreview({
    super.key,
    required this.wave,
    required this.accent,
    this.height = 48,
  });

  final int wave;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _WavePainter(wave: wave, color: accent),
        size: Size.infinite,
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.wave, required this.color});

  final int wave;
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
      final y = size.height * 0.5 - _sample(wave, phase) * size.height * 0.38;
      final x = t * size.width;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  double _sample(int wave, double phase) {
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
      oldDelegate.wave != wave || oldDelegate.color != color;
}
