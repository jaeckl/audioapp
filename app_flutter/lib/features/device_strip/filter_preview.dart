import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Filter modes (mirrors the engine-side `FilterParams::filterMode`).
enum FilterPreviewMode { lowPass, highPass, bandPass, notch }

/// Biquad coefficient set — mirrors `audioapp::BiquadCoeffs`.
class _BiquadCoeffs {
  const _BiquadCoeffs(this.b0, this.b1, this.b2, this.a1, this.a2);
  final double b0, b1, b2, a1, a2;
}

/// Reference sample rate for cooking biquads in the preview painter.
///
/// 48 kHz matches the engine offline render rate; the response is normalized
/// (relative to Nyquist) so the magnitude curve at any sampleRate ≈ the
/// magnitude at 48 kHz for musical frequencies.
const double _previewSampleRate = 48000.0;

_BiquadCoeffs _cookBiquad(int mode, double cutoffHz, double q) {
  final clampedCutoff = cutoffHz.clamp(20.0, _previewSampleRate * 0.45);
  final clampedQ = math.max(q, 0.1);
  final omega = 2.0 * math.pi * clampedCutoff / _previewSampleRate;
  final sinOmega = math.sin(omega);
  final cosOmega = math.cos(omega);
  final alpha = sinOmega / (2.0 * clampedQ);

  double b0 = 0, b1 = 0, b2 = 0;
  double a0 = 1, a1 = 0, a2 = 0;

  switch (mode) {
    case 1: // HP
      b0 = (1 + cosOmega) * 0.5;
      b1 = -(1 + cosOmega);
      b2 = (1 + cosOmega) * 0.5;
      a0 = 1 + alpha;
      a1 = -2 * cosOmega;
      a2 = 1 - alpha;
      break;
    case 2: // BP
      b0 = alpha;
      b1 = 0;
      b2 = -alpha;
      a0 = 1 + alpha;
      a1 = -2 * cosOmega;
      a2 = 1 - alpha;
      break;
    case 3: // notch
      b0 = 1;
      b1 = -2 * cosOmega;
      b2 = 1;
      a0 = 1 + alpha;
      a1 = -2 * cosOmega;
      a2 = 1 - alpha;
      break;
    case 0:
    default: // LP
      b0 = (1 - cosOmega) * 0.5;
      b1 = 1 - cosOmega;
      b2 = (1 - cosOmega) * 0.5;
      a0 = 1 + alpha;
      a1 = -2 * cosOmega;
      a2 = 1 - alpha;
      break;
  }

  return _BiquadCoeffs(b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0);
}

/// Biquad magnitude-response helpers shared by FilterPreview + FourBandEqPreview.
///
/// All helpers return **magnitude in dB** for a [frequencyHz] input.
abstract final class BiquadResponse {
  /// Magnitude (dB) of an LP/HP/BP/Notch biquad at [frequencyHz].
  ///
  /// [mode] is the same integer the engine uses (0=LP, 1=HP, 2=BP, 3=notch).
  static double compute({
    required double cutoffHz,
    required double q,
    required int mode,
    required double frequencyHz,
  }) {
    final coeffs = _cookBiquad(mode, cutoffHz, q);
    final w = 2 * math.pi * frequencyHz / _previewSampleRate;
    final cos1 = math.cos(w);
    final sin1 = math.sin(w);
    final cos2 = math.cos(2 * w);
    final sin2 = math.sin(2 * w);

    final numReal = coeffs.b0 + coeffs.b1 * cos1 + coeffs.b2 * cos2;
    final numImag = coeffs.b1 * sin1 + coeffs.b2 * sin2;
    final denReal = 1 + coeffs.a1 * cos1 + coeffs.a2 * cos2;
    final denImag = coeffs.a1 * sin1 + coeffs.a2 * sin2;

    final numMag = math.sqrt(numReal * numReal + numImag * numImag);
    final denMag = math.sqrt(denReal * denReal + denImag * denImag);
    if (numMag <= 1e-12 || denMag <= 1e-12) return -120.0;
    final linear = numMag / denMag;
    return 20 * math.log(linear) / math.ln10;
  }

  /// Low-shelf magnitude (dB) — RBJ "low shelf" formula.
  static double lowShelf({
    required double cutoffHz,
    required double q,
    required double gainDb,
    required double frequencyHz,
  }) =>
      _computeShelf(_ShelfKind.low, cutoffHz, q, gainDb, frequencyHz);

  /// High-shelf magnitude (dB) — RBJ "high shelf" formula.
  static double highShelf({
    required double cutoffHz,
    required double q,
    required double gainDb,
    required double frequencyHz,
  }) =>
      _computeShelf(_ShelfKind.high, cutoffHz, q, gainDb, frequencyHz);

  /// Peaking-EQ magnitude (dB) — RBJ "peaking EQ" formula.
  static double peakFilter({
    required double cutoffHz,
    required double q,
    required double gainDb,
    required double frequencyHz,
  }) =>
      _computePeak(cutoffHz, q, gainDb, frequencyHz);

  static double _computePeak(
    double cutoffHz,
    double q,
    double gainDb,
    double frequencyHz,
  ) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final clampedQ = math.max(q, 0.1);
    final omega = 2 * math.pi * cutoffHz / _previewSampleRate;
    final sinOmega = math.sin(omega);
    final cosOmega = math.cos(omega);
    final alpha = sinOmega / (2 * clampedQ);

    final b0 = 1 + alpha * a;
    final b1 = -2 * cosOmega;
    final b2 = 1 - alpha * a;
    final a0 = 1 + alpha / a;
    final a1 = -2 * cosOmega;
    final a2 = 1 - alpha / a;

    final w = 2 * math.pi * frequencyHz / _previewSampleRate;
    final cos1 = math.cos(w);
    final sin1 = math.sin(w);
    final cos2 = math.cos(2 * w);
    final sin2 = math.sin(2 * w);

    final numReal = b0 + b1 * cos1 + b2 * cos2;
    final numImag = b1 * sin1 + b2 * sin2;
    final denReal = a0 + a1 * cos1 + a2 * cos2;
    final denImag = a1 * sin1 + a2 * sin2;

    final numMag = math.sqrt(numReal * numReal + numImag * numImag);
    final denMag = math.sqrt(denReal * denReal + denImag * denImag);
    if (numMag <= 1e-12 || denMag <= 1e-12) return -120.0;
    final linear = numMag / denMag;
    return 20 * math.log(linear) / math.ln10;
  }

  static double _computeShelf(
    _ShelfKind kind,
    double cutoffHz,
    double q,
    double gainDb,
    double frequencyHz,
  ) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final clampedQ = math.max(q, 0.1);
    final omega = 2 * math.pi * cutoffHz / _previewSampleRate;
    final sinOmega = math.sin(omega);
    final cosOmega = math.cos(omega);
    final alpha = sinOmega / (2 * clampedQ);
    final twoSqrtAAlpha = 2 * math.sqrt(a) * alpha;

    double b0, b1, b2, a0, a1, a2;
    if (kind == _ShelfKind.low) {
      b0 = a * ((a + 1) - (a - 1) * cosOmega + twoSqrtAAlpha);
      b1 = 2 * a * ((a - 1) - (a + 1) * cosOmega);
      b2 = a * ((a + 1) - (a - 1) * cosOmega - twoSqrtAAlpha);
      a0 = (a + 1) + (a - 1) * cosOmega + twoSqrtAAlpha;
      a1 = -2 * ((a - 1) + (a + 1) * cosOmega);
      a2 = (a + 1) + (a - 1) * cosOmega - twoSqrtAAlpha;
    } else {
      b0 = a * ((a + 1) + (a - 1) * cosOmega + twoSqrtAAlpha);
      b1 = -2 * a * ((a - 1) + (a + 1) * cosOmega);
      b2 = a * ((a + 1) + (a - 1) * cosOmega - twoSqrtAAlpha);
      a0 = (a + 1) - (a - 1) * cosOmega + twoSqrtAAlpha;
      a1 = 2 * ((a - 1) - (a + 1) * cosOmega);
      a2 = (a + 1) - (a - 1) * cosOmega - twoSqrtAAlpha;
    }

    final w = 2 * math.pi * frequencyHz / _previewSampleRate;
    final cos1 = math.cos(w);
    final sin1 = math.sin(w);
    final cos2 = math.cos(2 * w);
    final sin2 = math.sin(2 * w);

    final numReal = b0 + b1 * cos1 + b2 * cos2;
    final numImag = b1 * sin1 + b2 * sin2;
    final denReal = a0 + a1 * cos1 + a2 * cos2;
    final denImag = a1 * sin1 + a2 * sin2;

    final numMag = math.sqrt(numReal * numReal + numImag * numImag);
    final denMag = math.sqrt(denReal * denReal + denImag * denImag);
    if (numMag <= 1e-12 || denMag <= 1e-12) return -120.0;
    final linear = numMag / denMag;
    return 20 * math.log(linear) / math.ln10;
  }
}

enum _ShelfKind { low, high }

/// Magnitude-response preview for the Filter device.
class FilterPreview extends StatelessWidget {
  const FilterPreview({
    super.key,
    required this.cutoffHz,
    required this.q,
    required this.mode,
    required this.accent,
  });

  final double cutoffHz;
  final double q;
  final FilterPreviewMode mode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FilterPreviewPainter(
        cutoffHz: cutoffHz,
        q: q,
        mode: mode,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

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