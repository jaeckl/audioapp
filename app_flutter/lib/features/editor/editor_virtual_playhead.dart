import 'package:flutter/material.dart';

import 'timeline_marker_layer.dart';

part 'editor_virtual_playhead_editor_virtual_playhead_pill.dart';
/// Visual playhead for in-editor preview (clip-local beats, not arrangement marker).
abstract final class EditorVirtualPlayheadTheme {
  static const Color color = Color(0xFFE8A54B);
  static const double pillSize = 30;
  static const double hitWidth = 44;
}

/// Line width for viewport-fixed editor playhead overlays.
const double editorVirtualPlayheadLineWidth = 2;

bool hitEditorVirtualPlayheadMarker({
  required double canvasDx,
  required double markerBeat,
  required double pixelsPerBeat,
  required double scrollOffset,
}) {
  return hitTimelineStickyPlayheadMarker(
    canvasDx: canvasDx,
    markerBeat: markerBeat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
    hitWidth: EditorVirtualPlayheadTheme.hitWidth,
  );
}

double clampEditorVirtualPlayheadBeat({
  required double beat,
  required double clipLengthBeats,
}) {
  return beat.clamp(0.0, clipLengthBeats);
}
