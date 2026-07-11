part of 'mood_fx_panels.dart';

class _TremoloPreviewPainter extends CustomPainter {
  _TremoloPreviewPainter({
    required this.depth,
    required this.shape,
    required this.accent,
  });

  final double depth;
  final double shape;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final cy = h / 2;
    final amp = (h - 12) / 2;
    const lfoCycles = 2.0;

    // LFO envelope guide (dashed line at top boundary)
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final guidePath = Path();
    for (double x = 0; x <= w; x += 1) {
      final t = x / w * lfoCycles;
      final lfo = _lfoValue(t, shape);
      final env = 1.0 - depth + depth * lfo;
      final ey = cy - env * amp;
      if (x == 0) {
        guidePath.moveTo(x, ey);
      } else {
        guidePath.lineTo(x, ey);
      }
    }
    // Draw dashed
    final metrics = guidePath.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + 3).clamp(0.0, metric.length);
        final seg = metric.extractPath(dist, end);
        canvas.drawPath(seg, guidePaint);
        dist += 7;
      }
    }

    // Filled modulated-carrier area
    final fillPath = Path();
    fillPath.moveTo(0, cy);
    for (double x = 0; x <= w; x += 1) {
      final t = x / w * lfoCycles;
      final lfo = _lfoValue(t, shape);
      final env = 1.0 - depth + depth * lfo;
      final carrier = math.sin(2 * math.pi * t * 3);
      final y = cy - carrier * env * amp;
      fillPath.lineTo(x, y);
    }
    // Mirror back along zero crossings – draw bottom edge
    for (double x = w; x >= 0; x -= 1) {
      final t = x / w * lfoCycles;
      final lfo = _lfoValue(t, shape);
      final env = 1.0 - depth + depth * lfo;
      final carrier = math.sin(2 * math.pi * t * 3);
      final y = cy + carrier * env * amp;
      fillPath.lineTo(x, y);
    }
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.5),
            accent.withValues(alpha: 0.06),
          ],
        ).createShader(Offset.zero & size),
    );

    // Carrier outline for clarity
    final carrierPaint = Paint()
      ..color = accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final carrierPath = Path();
    carrierPath.moveTo(0, cy);
    for (double x = 0; x <= w; x += 1) {
      final t = x / w * lfoCycles;
      final lfo = _lfoValue(t, shape);
      final env = 1.0 - depth + depth * lfo;
      final carrier = math.sin(2 * math.pi * t * 3);
      final y = cy - carrier * env * amp;
      carrierPath.lineTo(x, y);
    }
    canvas.drawPath(carrierPath, carrierPaint);
  }

  static double _lfoValue(double cycles, double shape) {
    if (shape < 0.5) {
      return 0.5 + 0.5 * math.sin(2 * math.pi * cycles);
    }
    return (math.sin(2 * math.pi * cycles) >= 0) ? 1.0 : 0.0;
  }

  @override
  bool shouldRepaint(covariant _TremoloPreviewPainter old) =>
      old.depth != depth || old.shape != shape || old.accent != accent;
}
