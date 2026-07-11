part of 'mood_fx_panels.dart';

class _DistortionPreviewPainter extends CustomPainter {
  _DistortionPreviewPainter({
    required this.drive,
    required this.accent,
  });

  final double drive;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final cx = w / 2;
    final cy = h / 2;
    final scale = (math.min(cx, cy) - 4);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, cy), Offset(w, cy), gridPaint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, h), gridPaint);

    // Diagonal reference (clean signal)
    final refPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(cx - scale, cy - scale),
      Offset(cx + scale, cy + scale),
      refPaint,
    );

    // Waveshaping curve
    final gain = 0.3 + drive * 4.0;
    final tanhGain = _tanh(gain);

    final curvePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    final curvePath = Path();

    for (double px = 0; px <= w; px += 1) {
      final input = (px / w) * 2 - 1;
      final output = _tanh(input * gain) / tanhGain;
      final py = cy - output * scale;
      if (px == 0) {
        curvePath.moveTo(px, py);
      } else {
        curvePath.lineTo(px, py);
      }
    }
    canvas.drawPath(curvePath, curvePaint);

    // Filled area under curve
    final fillPath = Path();
    fillPath.moveTo(cx - scale, cy);
    for (double px = 0; px <= w; px += 1) {
      final input = (px / w) * 2 - 1;
      final output = _tanh(input * gain) / tanhGain;
      final py = cy - output * scale;
      fillPath.lineTo(px, py);
    }
    fillPath.lineTo(cx + scale, cy);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.45),
            accent.withValues(alpha: 0.04),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  static double _tanh(double x) {
    if (x > 20) return 1;
    if (x < -20) return -1;
    final exp2x = math.exp(2 * x);
    return (exp2x - 1) / (exp2x + 1);
  }

  @override
  bool shouldRepaint(covariant _DistortionPreviewPainter old) =>
      old.drive != drive || old.accent != accent;
}
