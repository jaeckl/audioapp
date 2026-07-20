part of 'eq_preview.dart';

/// Shared log-Hz / dB mapping for EQ curve + handles.
abstract final class EqPreviewGeometry {
  static const double minFreq = 20.0;
  static const double maxFreq = 20000.0;
  static const double minDb = -24.0;
  static const double maxDb = 24.0;

  /// Contract: interactive nodes ≥28px.
  static const double hitRadius = 28.0;

  /// Left = dB scale, bottom = Hz scale (Filter grammar).
  static const double padL = 22.0;
  static const double padR = 8.0;
  static const double padT = 4.0;
  static const double padB = 14.0;
  static const double curveInset = 4.0;

  static const freqLabels = <(double, String)>[
    (20.0, '20'),
    (100.0, '100'),
    (1000.0, '1k'),
    (10000.0, '10k'),
    (20000.0, '20k'),
  ];

  static const dbLabels = <(double, String)>[
    (24.0, '+24'),
    (12.0, '+12'),
    (0.0, '0'),
    (-12.0, '−12'),
    (-24.0, '−24'),
  ];

  static Rect plotRect(Size size) => Rect.fromLTWH(
        padL,
        padT,
        math.max(0.0, size.width - padL - padR),
        math.max(0.0, size.height - padT - padB),
      );

  static Rect curveRect(Size size) {
    final plot = plotRect(size);
    if (plot.width <= 0 || plot.height <= 0) return plot;
    return plot.deflate(curveInset);
  }

  static double freqToX(double f, double w) {
    final clamped = f.clamp(minFreq, maxFreq);
    final norm = math.log(clamped / minFreq) / math.log(maxFreq / minFreq);
    return norm * w;
  }

  static double xToFreq(double x, double w) {
    if (w <= 0) return minFreq;
    final norm = (x / w).clamp(0.0, 1.0);
    return minFreq * math.pow(maxFreq / minFreq, norm);
  }

  static double dbToY(double db, double h) {
    final clamped = db.clamp(minDb, maxDb);
    return h * (1.0 - (clamped - minDb) / (maxDb - minDb));
  }

  static double yToDb(double y, double h) {
    if (h <= 0) return 0.0;
    final t = (1.0 - (y / h)).clamp(0.0, 1.0);
    return minDb + t * (maxDb - minDb);
  }

  /// Matches engine `normalizedToFrequency` inverse (`20 * 1000^n`).
  static double hzToNorm(double hz) {
    final clamped = hz.clamp(minFreq, maxFreq);
    return math.log(clamped / minFreq) / math.log(1000.0);
  }

  /// Matches engine ±24 dB gain map.
  static double dbToNorm(double db) =>
      ((db - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);

  static Offset handleOffset(EqBand band, Size size) {
    final curve = curveRect(size);
    return Offset(
      curve.left + freqToX(band.cutoffHz, curve.width),
      curve.top + dbToY(band.gainDb, curve.height),
    );
  }

  static double localToFreq(double localX, Size size) {
    final curve = curveRect(size);
    return xToFreq(localX - curve.left, curve.width);
  }

  static double localToDb(double localY, Size size) {
    final curve = curveRect(size);
    return yToDb(localY - curve.top, curve.height);
  }
}
