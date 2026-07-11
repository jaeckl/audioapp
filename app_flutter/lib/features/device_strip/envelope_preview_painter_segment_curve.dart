part of 'envelope_preview_painter.dart';

class _SegmentCurve {
  const _SegmentCurve({
    required this.param, // the curve param name e.g. "attackCurve"
    required this.xStart,
    required this.xEnd,
    required this.yStart,
    required this.yEnd,
    required this.curve,
  });

  final String param;
  final double xStart;
  final double xEnd;
  final double yStart;
  final double yEnd;
  final double curve;

  double get midX => (xStart + xEnd) / 2;
  double get midY => (yStart + yEnd) / 2;

  /// Y position at the straight-line midpoint, adjusted by curvature.
  /// When curve=0.5 it's exactly midY. Below 0.5 bends away from the line peak,
  /// above 0.5 bends toward it.
  double get curvedMidY {
    const t = 0.5;
    final eased = easeCurve(t, curve);
    if (yEnd < yStart) {
      // rising (attack)
      return yStart - (yStart - yEnd) * eased;
    }
    // falling (decay, release)
    return yStart + (yEnd - yStart) * eased;
  }
}
