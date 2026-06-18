import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pitch-drop + amp envelope preview for the kick generator strip.
class KickEnvelopePreview extends StatelessWidget {
  const KickEnvelopePreview({
    super.key,
    required this.pitch,
    required this.punch,
    required this.decay,
    required this.click,
    required this.accent,
  });

  final double pitch;
  final double punch;
  final double decay;
  final double click;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _KickEnvelopePainter(
        pitch: pitch,
        punch: punch,
        decay: decay,
        click: click,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _KickEnvelopePainter extends CustomPainter {
  _KickEnvelopePainter({
    required this.pitch,
    required this.punch,
    required this.decay,
    required this.click,
    required this.accent,
  });

  final double pitch;
  final double punch;
  final double decay;
  final double click;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0E0E14);
    canvas.drawRect(Offset.zero & size, bg);

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final startHz = 80 + pitch.clamp(0.0, 1.0) * 120;
    final endHz = 35 + (1 - punch.clamp(0.0, 1.0)) * 25;
    final pitchTau = 0.04 + (1 - punch.clamp(0.0, 1.0)) * 0.12;
    final ampTau = 0.08 + (1 - decay.clamp(0.0, 1.0)) * 0.42;
    const duration = 0.45;

    final pitchPath = Path();
    final ampPath = Path();
    const steps = 64;
    for (var i = 0; i <= steps; i++) {
      final t = duration * i / steps;
      final x = size.width * i / steps;
      final hz = endHz + (startHz - endHz) * math.exp(-t / pitchTau);
      final pitchY = size.height * (1 - ((hz - 30) / 170).clamp(0.0, 1.0) * 0.75) - 8;
      final amp = math.exp(-t / ampTau);
      final ampY = size.height * 0.82 - amp * size.height * 0.55;
      if (i == 0) {
        pitchPath.moveTo(x, pitchY);
        ampPath.moveTo(x, ampY);
      } else {
        pitchPath.lineTo(x, pitchY);
        ampPath.lineTo(x, ampY);
      }
    }

    canvas.drawPath(
      ampPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawPath(
      pitchPath,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    if (click > 0.02) {
      final clickHeight = size.height * 0.18 * click.clamp(0.0, 1.0);
      final clickPath = Path()
        ..moveTo(4, size.height * 0.82)
        ..lineTo(4 + size.width * 0.06, size.height * 0.82 - clickHeight)
        ..lineTo(4 + size.width * 0.12, size.height * 0.82);
      canvas.drawPath(
        clickPath,
        Paint()
          ..color = accent.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final label = TextPainter(
      text: TextSpan(
        text: 'PITCH + AMP',
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
  bool shouldRepaint(covariant _KickEnvelopePainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.punch != punch ||
        oldDelegate.decay != decay ||
        oldDelegate.click != click ||
        oldDelegate.accent != accent;
  }
}

String kickPitchLabel(double norm) {
  final hz = (80 + norm.clamp(0.0, 1.0) * 120).round();
  return '$hz Hz';
}

String kickDecayLabel(double norm) {
  final ms = (80 + (1 - norm.clamp(0.0, 1.0)) * 420).round();
  return '${ms}ms';
}
