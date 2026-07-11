part of 'eq_preview.dart';

class _EqPreviewPainter extends CustomPainter {
  _EqPreviewPainter({required this.bands, required this.accent});

  final List<EqBand> bands;
  final Color accent;

  static const double _minFreq = 20.0;
  static const double _maxFreq = 20000.0;
  static const double _minDb = -18.0;
  static const double _maxDb = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0E0E14),
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    for (final f in const [100.0, 1000.0, 10000.0]) {
      final x = _freqToX(f, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double db = -18; db <= 18; db += 6) {
      final y = _dbToY(db, size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
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

    // Per-band tinted markers (small triangles at band centers).
    for (final band in bands) {
      final clamped = band.cutoffHz.clamp(_minFreq, _maxFreq);
      final x = _freqToX(clamped, size.width);
      final markerPaint = Paint()
        ..color = accent.withValues(alpha: 0.30)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(x, size.height * 0.10),
        Offset(x, size.height * 0.90),
        markerPaint,
      );
    }

    // Combined magnitude curve.
    final path = Path();
    final stepCount = math.max(60, size.width.toInt());
    for (var i = 0; i <= stepCount; i++) {
      final t = i / stepCount;
      final x = t * size.width;
      final f = _xToFreq(x, size.width);
      var totalDb = 0.0;
      for (final band in bands) {
        final bandDb = band.isShelf
            ? (band == bands.first
                ? BiquadResponse.lowShelf(
                    cutoffHz: band.cutoffHz,
                    q: band.q,
                    gainDb: band.gainDb,
                    frequencyHz: f,
                  )
                : BiquadResponse.highShelf(
                    cutoffHz: band.cutoffHz,
                    q: band.q,
                    gainDb: band.gainDb,
                    frequencyHz: f,
                  ))
            : BiquadResponse.peakFilter(
                cutoffHz: band.cutoffHz,
                q: band.q,
                gainDb: band.gainDb,
                frequencyHz: f,
              );
        totalDb += bandDb;
      }
      final y = _dbToY(totalDb, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static double _freqToX(double f, double w) {
    final clamped = f.clamp(_minFreq, _maxFreq);
    final norm = math.log(clamped / _minFreq) / math.log(_maxFreq / _minFreq);
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
  bool shouldRepaint(covariant _EqPreviewPainter old) {
    if (old.accent != accent) return true;
    if (old.bands.length != bands.length) return true;
    for (var i = 0; i < bands.length; i++) {
      final a = old.bands[i];
      final b = bands[i];
      if (a.cutoffHz != b.cutoffHz ||
          a.gainDb != b.gainDb ||
          a.q != b.q ||
          a.isShelf != b.isShelf) {
        return true;
      }
    }
    return false;
  }
}
