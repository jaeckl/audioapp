part of 'sampler_envelope_preview.dart';

class _SamplerEnvelopePainter extends CustomPainter {
  _SamplerEnvelopePainter({
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.accent,
    required this.label,
  });

  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final Color accent;
  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0E0E14));

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final attackSec = samplerAdsrStageSec(attack, 2.0);
    final decaySec = samplerAdsrStageSec(decay, 2.0);
    final releaseSec = samplerAdsrStageSec(release, 3.0);
    const noteDurationSec = 0.35;
    final totalSec = attackSec + decaySec + noteDurationSec + releaseSec + 0.05;

    final path = Path();
    const steps = 72;
    for (var i = 0; i <= steps; i++) {
      final t = totalSec * i / steps;
      final gain = samplerAdsrDisplayGain(
        t,
        noteDurationSec,
        attackSec: attackSec,
        decaySec: decaySec,
        sustainLevel: sustain,
        releaseSec: releaseSec,
      );
      final x = size.width * i / steps;
      final y = size.height - 4 - gain.clamp(0.0, 1.0) * (size.height - 10);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = accent.withValues(alpha: 0.12),
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.22),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(canvas, const Offset(6, 4));
  }

  @override
  bool shouldRepaint(covariant _SamplerEnvelopePainter oldDelegate) {
    return oldDelegate.attack != attack ||
        oldDelegate.decay != decay ||
        oldDelegate.sustain != sustain ||
        oldDelegate.release != release ||
        oldDelegate.accent != accent ||
        oldDelegate.label != label;
  }
}
