part of 'filter_preview.dart';

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
