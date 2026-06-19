import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shimmering decay preview for the cymbal/crash generator strip.
class CymbalDecayPreview extends StatelessWidget {
  const CymbalDecayPreview({
    super.key,
    required this.color,
    required this.decay,
    required this.accent,
  });

  final double color;
  final double decay;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CymbalDecayPainter(
        color: color,
        decay: decay,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CymbalDecayPainter extends CustomPainter {
  _CymbalDecayPainter({
    required this.color,
    required this.decay,
    required this.accent,
  });

  final double color;
  final double decay;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0E0E14);
    canvas.drawRect(Offset.zero & size, bg);

    final ampTau = 0.4 + (1 - decay.clamp(0.0, 1.0)) * 2.6;
    const duration = 1.2;
    const steps = 72;
    final shimmerRate = 8 + color.clamp(0.0, 1.0) * 12;
    final ampScale = 0.15 + color.clamp(0.0, 1.0) * 0.35;

    for (var band = 0; band < 6; band++) {
      final path = Path();
      final bandOffset = band * 3.0;
      for (var i = 0; i <= steps; i++) {
        final t = duration * i / steps;
        final x = size.width * i / steps;
        final shimmer = math.sin(t * (shimmerRate + band)) * 2;
        final amp = math.exp(-t / ampTau) * ampScale;
        final y = size.height * 0.78 - amp * size.height * (0.35 - band * 0.04) + shimmer;
        if (i == 0) {
          path.moveTo(x, y + bandOffset);
        } else {
          path.lineTo(x, y + bandOffset);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: 0.12 + band * 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final label = TextPainter(
      text: TextSpan(
        text: 'METAL DECAY',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.22),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, const Offset(6, 6));
  }

  @override
  bool shouldRepaint(covariant _CymbalDecayPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.decay != decay ||
        oldDelegate.accent != accent;
  }
}

String cymbalDecayLabel(double norm) {
  final sec = 0.035 + norm.clamp(0.0, 1.0) * 0.70;
  return sec >= 1.0 ? '${sec.toStringAsFixed(1)}s' : '${(sec * 1000).round()}ms';
}
