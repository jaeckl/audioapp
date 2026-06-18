import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dual-layer body + snares preview for the snare generator strip.
class SnareEnvelopePreview extends StatelessWidget {
  const SnareEnvelopePreview({
    super.key,
    required this.body,
    required this.tune,
    required this.snares,
    required this.snap,
    required this.decay,
    required this.accent,
  });

  final double body;
  final double tune;
  final double snares;
  final double snap;
  final double decay;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SnareEnvelopePainter(
        body: body,
        tune: tune,
        snares: snares,
        snap: snap,
        decay: decay,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SnareEnvelopePainter extends CustomPainter {
  _SnareEnvelopePainter({
    required this.body,
    required this.tune,
    required this.snares,
    required this.snap,
    required this.decay,
    required this.accent,
  });

  final double body;
  final double tune;
  final double snares;
  final double snap;
  final double decay;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0E0E14);
    canvas.drawRect(Offset.zero & size, bg);

    const duration = 0.45;
    const steps = 64;
    final bodyTau = 0.04 + (1 - body.clamp(0.0, 1.0)) * 0.08;
    final noiseTau = 0.12 + (1 - snares.clamp(0.0, 1.0)) * 0.28;
    final ampTau = 0.15 + (1 - decay.clamp(0.0, 1.0)) * 0.35;

    final bodyPath = Path();
    final snaresPath = Path();
    final ampPath = Path();

    for (var i = 0; i <= steps; i++) {
      final t = duration * i / steps;
      final x = size.width * i / steps;
      final bodyEnv = math.exp(-t / bodyTau) * (0.25 + body.clamp(0.0, 1.0) * 0.55);
      final noiseEnv = math.exp(-t / noiseTau) * (0.2 + snares.clamp(0.0, 1.0) * 0.65);
      final amp = math.exp(-t / ampTau);
      final bodyY = size.height * 0.55 - bodyEnv * size.height * 0.35;
      final noiseY = size.height * 0.72 - noiseEnv * size.height * 0.22 +
          math.sin(t * (600 + tune.clamp(0.0, 1.0) * 2400) * 0.02) * 3;
      final ampY = size.height * 0.82 - amp * size.height * 0.55;
      if (i == 0) {
        bodyPath.moveTo(x, bodyY);
        snaresPath.moveTo(x, noiseY);
        ampPath.moveTo(x, ampY);
      } else {
        bodyPath.lineTo(x, bodyY);
        snaresPath.lineTo(x, noiseY);
        ampPath.lineTo(x, ampY);
      }
    }

    canvas.drawPath(
      ampPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawPath(
      snaresPath,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    if (snap > 0.02) {
      final snapHeight = size.height * 0.16 * snap.clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(4, size.height * 0.55),
        Offset(4 + size.width * 0.05, size.height * 0.55 - snapHeight),
        Paint()
          ..color = accent.withValues(alpha: 0.7)
          ..strokeWidth = 2,
      );
    }

    final label = TextPainter(
      text: TextSpan(
        text: 'BODY + SNARES',
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
  bool shouldRepaint(covariant _SnareEnvelopePainter oldDelegate) {
    return oldDelegate.body != body ||
        oldDelegate.tune != tune ||
        oldDelegate.snares != snares ||
        oldDelegate.snap != snap ||
        oldDelegate.decay != decay ||
        oldDelegate.accent != accent;
  }
}

String snareTuneLabel(double norm) {
  final hz = (120 + norm.clamp(0.0, 1.0) * 160).round();
  return '$hz Hz';
}

String snareDecayLabel(double norm) {
  final ms = (150 + (1 - norm.clamp(0.0, 1.0)) * 350).round();
  return '${ms}ms';
}
