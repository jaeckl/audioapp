part of 'timeline_marker_layer.dart';

bool hitTimelineStickyPlayheadMarker({
  required double canvasDx,
  required double markerBeat,
  required double pixelsPerBeat,
  required double scrollOffset,
  required double hitWidth,
}) {
  final markerX = timelineStickyMarkerCanvasX(
    beat: markerBeat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
  return (canvasDx - markerX).abs() <= hitWidth / 2;
}
