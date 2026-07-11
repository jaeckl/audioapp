part of 'timeline_marker_layer.dart';

abstract final class TimelineFollowMetrics {
  /// Playhead sits this fraction from the left edge while following.
  static const double leadFraction = 0.25;

  /// Follow when the playhead passes this rightward bound.
  static const double maxVisibleFraction = 0.85;
}
