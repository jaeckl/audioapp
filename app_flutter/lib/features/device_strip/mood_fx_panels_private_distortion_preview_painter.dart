part of 'mood_fx_panels.dart';

/// Tanh transfer curve — Drive + Sym reshape the plot (§4 PASS).
class _DistortionPreviewPainter extends CustomPainter {
  _DistortionPreviewPainter({
    required this.drive,
    required this.sym,
    required this.accent,
  });

  final double drive;
  final double sym;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Hero fill comes from FilterSectionLayout.
    final pad = const EdgeInsets.fromLTRB(10, 12, 10, 8);
    final plot = Rect.fromLTRB(
      pad.left,
      pad.top,
      size.width - pad.right,
      size.height - pad.bottom,
    );
    if (plot.width <= 4 || plot.height <= 4) return;

    final cx = plot.center.dx;
    final cy = plot.center.dy;
    final scale = math.min(plot.width, plot.height) * 0.42;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(plot.left, cy), Offset(plot.right, cy), gridPaint);
    canvas.drawLine(Offset(cx, plot.top), Offset(cx, plot.bottom), gridPaint);

    final refPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(cx - scale, cy + scale),
      Offset(cx + scale, cy - scale),
      refPaint,
    );

    final driveGain = drive.clamp(0.0, 1.0) * 8.0 + 0.5;
    final bias = (sym.clamp(0.0, 1.0) - 0.5) * 1.2;
    final dc = _tanh(bias * driveGain);

    final curvePath = Path();
    final fillPath = Path()..moveTo(cx - scale, cy);
    var started = false;
    for (double px = plot.left; px <= plot.right; px += 1) {
      final input = ((px - cx) / scale).clamp(-1.5, 1.5);
      final output = (_tanh((input + bias) * driveGain) - dc).clamp(-1.2, 1.2);
      final py = cy - output * scale;
      if (!started) {
        curvePath.moveTo(px, py);
        started = true;
      } else {
        curvePath.lineTo(px, py);
      }
      fillPath.lineTo(px, py);
    }
    fillPath.lineTo(cx + scale, cy);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()..color = accent.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'DRIVE ${(drive * 100).round()}%  ·  SYM ${_symLabel(sym)}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: plot.width);
    tp.paint(canvas, Offset(plot.left, plot.top - 2));
  }

  static String _symLabel(double sym) {
    final bias = ((sym - 0.5) * 200).round();
    if (bias == 0) return '0';
    return bias > 0 ? '+$bias' : '$bias';
  }

  static double _tanh(double x) {
    if (x > 20) return 1;
    if (x < -20) return -1;
    final exp2x = math.exp(2 * x);
    return (exp2x - 1) / (exp2x + 1);
  }

  @override
  bool shouldRepaint(covariant _DistortionPreviewPainter old) =>
      old.drive != drive || old.sym != sym || old.accent != accent;
}
