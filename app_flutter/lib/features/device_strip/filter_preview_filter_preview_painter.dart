part of 'filter_preview.dart';

class _FilterPreviewPainter extends CustomPainter {
  _FilterPreviewPainter({
    required this.cutoffHz,
    required this.q,
    required this.mode,
    required this.accent,
  });

  final double cutoffHz;
  final double q;
  final FilterPreviewMode mode;
  final Color accent;

  static const double _minFreq = 20.0;
  static const double _maxFreq = 20000.0;
  static const double _minDb = -24.0;
  static const double _maxDb = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E0E14),
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    // Vertical frequency markers (logarithmic decades: 100, 1k, 10k).
    const markers = [100.0, 1000.0, 10000.0];
    for (final f in markers) {
      final x = _freqToX(f, size.width);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Horizontal dB markers (every 6 dB from _minDb to _maxDb).
    for (double db = -24; db <= 12; db += 6) {
      final y = _dbToY(db, size.height);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 0 dB baseline (slightly brighter).
    final zeroY = _dbToY(0, size.height);
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.0,
    );

    // Magnitude curve.
    final path = Path();
    final stepCount = math.max(60, size.width.toInt());
    for (var i = 0; i <= stepCount; i++) {
      final t = i / stepCount;
      final x = t * size.width;
      final f = _xToFreq(x, size.width);
      final db = BiquadResponse.compute(
        cutoffHz: cutoffHz,
        q: q,
        mode: mode.index,
        frequencyHz: f,
      );
      final y = _dbToY(db, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final curvePaint = Paint()
      ..color = accent.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, curvePaint);

    // Cutoff tick mark.
    final cutoffX = _freqToX(cutoffHz.clamp(_minFreq, _maxFreq), size.width);
    final tickPaint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(cutoffX, size.height * 0.12),
      Offset(cutoffX, size.height * 0.88),
      tickPaint,
    );
  }

  static double _freqToX(double f, double w) {
    final clamped = f.clamp(_minFreq, _maxFreq);
    final norm = (math.log(clamped / _minFreq)) / math.log(_maxFreq / _minFreq);
    return norm * w;
  }

  static double _xToFreq(double x, double w) {
    final norm = (x / w).clamp(0.0, 1.0);
    return _minFreq * math.pow(_maxFreq / _minFreq, norm);
  }

  static double _dbToY(double db, double h) {
    final clamped = db.clamp(_minDb, _maxDb);
    return h * (1.0 - (clamped - _minDb) / (_maxDb - _minDb));
  }

  @override
  bool shouldRepaint(covariant _FilterPreviewPainter old) =>
      old.cutoffHz != cutoffHz ||
      old.q != q ||
      old.mode != mode ||
      old.accent != accent;
}
