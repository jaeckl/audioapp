part of 'timeline_marker_layer.dart';

double timelineStickyMarkerCanvasX({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  final displayViewportX = timelineStickyViewportX(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  );
  return displayViewportX + scrollOffset;
}
