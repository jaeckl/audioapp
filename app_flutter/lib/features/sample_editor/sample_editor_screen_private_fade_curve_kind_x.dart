part of 'sample_editor_screen.dart';

extension _FadeCurveKindX on _FadeCurveKind {
  double get value => switch (this) {
        _FadeCurveKind.linear => 0.0,
        _FadeCurveKind.quadratic => 0.33,
        _FadeCurveKind.cubic => 0.66,
        _FadeCurveKind.smooth => 1.0,
      };

  static _FadeCurveKind fromValue(double value) {
    var closest = _FadeCurveKind.linear;
    var distance = (value - closest.value).abs();
    for (final kind in _FadeCurveKind.values.skip(1)) {
      final next = (value - kind.value).abs();
      if (next < distance) {
        closest = kind;
        distance = next;
      }
    }
    return closest;
  }
}
