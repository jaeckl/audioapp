part of 'timeline_marker_layer.dart';

void partitionBeatMarker({
  required double beat,
  required double pixelsPerBeat,
  required double scrollOffset,
  required Widget pill,
  required Widget line,
  required List<Widget> behindPills,
  required List<Widget> behindLines,
  required List<Widget> frontPills,
  required List<Widget> frontLines,
}) {
  if (timelineMarkerAtViewportOrigin(
    beat: beat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
  )) {
    frontPills.add(pill);
    frontLines.add(line);
  } else {
    behindPills.add(pill);
    behindLines.add(line);
  }
}
