part of 'timeline_marker_layer.dart';

double timelineLeadViewportX(
  double viewportWidth, {
  double leadFraction = TimelineFollowMetrics.leadFraction,
}) {
  return viewportWidth * leadFraction;
}
