import 'dart:math' as math;

/// Shared normalized→real and display formatters for device panels.
abstract final class DeviceParamFormatters {
  static double cutoffHzFromNormalized(double normalized) {
    final clamped = normalized.clamp(0.0, 1.0);
    return 20.0 * math.pow(1000.0, clamped);
  }

  static double qFromNormalized(double normalized) {
    return 0.1 + normalized.clamp(0.0, 1.0) * 19.9;
  }

  static String formatCutoffHz(double normalized) {
    final hz = cutoffHzFromNormalized(normalized);
    if (hz >= 10000) return '${(hz / 1000).toStringAsFixed(1)} kHz';
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(2)} kHz';
    return '${hz.round()} Hz';
  }

  static String formatQ(double normalized) {
    return qFromNormalized(normalized).toStringAsFixed(2);
  }

  static String formatPercent(double normalized) {
    return '${(normalized.clamp(0.0, 1.0) * 100).round()}%';
  }
}
