part of 'filter_mode_icons.dart';

abstract final class FilterFxModeNorm {
  /// Bin centres matching engine `lround(ffxFilterMode * 3)` → 0..3.
  static const values = <double>[0.125, 0.375, 0.625, 0.875];

  /// Nearest discrete mode index for a normalised engine value.
  static int indexFrom(double norm) {
    final n = norm.clamp(0.0, 1.0);
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < values.length; i++) {
      final d = (n - values[i]).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }
}
