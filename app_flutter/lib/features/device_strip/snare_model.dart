/// Snare engine model selection (`snareModel` param 0…1 → discrete index).
abstract final class SnareModel {
  static const labels = ['Acoustic', 'Tight', '909'];

  static int indexFromValue(double value) =>
      (value.clamp(0.0, 1.0) * 2).round().clamp(0, labels.length - 1);

  static double valueFromIndex(int index) =>
      index.clamp(0, labels.length - 1) / 2.0;

  static String labelFromValue(double value) => labels[indexFromValue(value)];

  /// v1: only Acoustic is selectable.
  static bool isSelectable(int index) => index == 0;
}
