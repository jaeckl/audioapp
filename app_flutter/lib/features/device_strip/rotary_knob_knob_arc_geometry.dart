part of 'rotary_knob.dart';

abstract final class KnobArcGeometry {
  static const double start = math.pi * (5.0 / 6.0); // 150° — south-west
  static const double sweep =
      math.pi * (4.0 / 3.0); // +240° clockwise → south-east

  static double indicatorAngle(double value) =>
      start + value.clamp(0.0, 1.0) * sweep;

  static const double _edgeInset = 2.0;
  static const double _innerDiscInset = 6.0;

  /// Knob arc radius for a square [knobSize] widget.
  static double radius(double knobSize) => knobSize / 2 - _edgeInset;

  /// Perceived dial center — midpoint between arc apex and inner disc bottom.
  static Offset visualCenter(Size knobSize) {
    final geometric = Offset(knobSize.width / 2, knobSize.height / 2);
    final r = radius(knobSize.width);
    final arcTopY = geometric.dy - r;
    final discBottomY = geometric.dy + r - _innerDiscInset;
    return Offset(geometric.dx, (arcTopY + discBottomY) / 2);
  }

  /// [visualCenter] mapped into a host where the knob square is centered.
  static Offset visualCenterInCenteredHost({
    required double knobSize,
    required Size hostSize,
  }) {
    final knobVisual = visualCenter(Size(knobSize, knobSize));
    final padX = (hostSize.width - knobSize) / 2;
    final padY = (hostSize.height - knobSize) / 2;
    return Offset(padX + knobVisual.dx, padY + knobVisual.dy);
  }
}
