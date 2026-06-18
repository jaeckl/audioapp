import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Staggered burst timeline preview for the clap generator strip.
class ClapBurstPreview extends StatelessWidget {
  const ClapBurstPreview({
    super.key,
    required this.bursts,
    required this.spread,
    required this.decay,
    required this.accent,
  });

  final double bursts;
  final double spread;
  final double decay;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ClapBurstPainter(
        bursts: bursts,
        spread: spread,
        decay: decay,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ClapBurstPainter extends CustomPainter {
  _ClapBurstPainter({
    required this.bursts,
    required this.spread,
    required this.decay,
    required this.accent,
  });

  final double bursts;
  final double spread;
  final double decay;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0E0E14);
    canvas.drawRect(Offset.zero & size, bg);

    final count = 2 + (bursts.clamp(0.0, 1.0) * 3).round();
    final interval = 0.008 + (1 - spread.clamp(0.0, 1.0)) * 0.010;
    final ampTau = 0.12 + (1 - decay.clamp(0.0, 1.0)) * 0.38;
    const duration = 0.35;

    for (var i = 0; i < count; i++) {
      final offset = i * interval + spread.clamp(0.0, 1.0) * 0.003 * i;
      final x = (offset / duration).clamp(0.0, 1.0) * (size.width - 16) + 8;
      final height = size.height * (0.35 + (1 - i / count) * 0.35) *
          math.exp(-offset / ampTau);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, size.height * 0.72), width: 6, height: height),
          const Radius.circular(2),
        ),
        Paint()..color = accent.withValues(alpha: 0.55 + (1 - i / count) * 0.35),
      );
    }

    final label = TextPainter(
      text: TextSpan(
        text: 'BURST TIMELINE',
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
  bool shouldRepaint(covariant _ClapBurstPainter oldDelegate) {
    return oldDelegate.bursts != bursts ||
        oldDelegate.spread != spread ||
        oldDelegate.decay != decay ||
        oldDelegate.accent != accent;
  }
}

String clapBurstsLabel(double norm) {
  final count = 2 + (norm.clamp(0.0, 1.0) * 3).round();
  return '$count hits';
}

String clapDecayLabel(double norm) {
  final ms = (120 + (1 - norm.clamp(0.0, 1.0)) * 380).round();
  return '${ms}ms';
}
