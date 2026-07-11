part of 'timeline_marker_layer.dart';

bool timelinePlayheadNeedsFollow({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
  required double viewportWidth,
  double leadFraction = TimelineFollowMetrics.leadFraction,
  double maxVisibleFraction = TimelineFollowMetrics.maxVisibleFraction,
}) {
  if (viewportWidth <= 0) {
    return false;
  }
  final natural = timelineNaturalViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
  final leadX = timelineLeadViewportX(viewportWidth, leadFraction: leadFraction);
  final maxX = viewportWidth * maxVisibleFraction;
  return natural < leadX || natural > maxX;
}
