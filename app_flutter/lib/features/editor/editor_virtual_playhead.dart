import 'package:flutter/material.dart';

import 'timeline_marker_layer.dart';

/// Visual playhead for in-editor preview (clip-local beats, not arrangement marker).
abstract final class EditorVirtualPlayheadTheme {
  static const Color color = Color(0xFFE8A54B);
  static const double pillSize = 30;
  static const double hitWidth = 44;
}

class EditorVirtualPlayheadPill extends StatelessWidget {
  const EditorVirtualPlayheadPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        elevation: 4,
        color: EditorVirtualPlayheadTheme.color,
        shape: const CircleBorder(),
        child: SizedBox(
          width: EditorVirtualPlayheadTheme.pillSize,
          height: EditorVirtualPlayheadTheme.pillSize,
          child: const Icon(Icons.play_arrow, size: 18, color: Color(0xFF1A1408)),
        ),
      ),
    );
  }
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
