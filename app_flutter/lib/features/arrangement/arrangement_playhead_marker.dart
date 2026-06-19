import 'package:flutter/material.dart';

import '../editor/timeline_marker_layer.dart';

/// Arrangement playhead handle on the beat ruler (larger than loop region pills).
abstract final class ArrangementPlayheadMarkerTheme {
  static const double pillSize = 30;
  static const double hitWidth = 44;
}

class ArrangementPlayheadRulerPill extends StatelessWidget {
  const ArrangementPlayheadRulerPill({
    super.key,
    required this.color,
    required this.iconColor,
    required this.playing,
  });

  final Color color;
  final Color iconColor;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        elevation: 4,
        color: color,
        shape: const CircleBorder(),
        child: SizedBox(
          width: ArrangementPlayheadMarkerTheme.pillSize,
          height: ArrangementPlayheadMarkerTheme.pillSize,
          child: Icon(
            playing ? Icons.stop : Icons.play_arrow,
            size: 18,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

bool hitArrangementPlayheadMarker({
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
    hitWidth: ArrangementPlayheadMarkerTheme.hitWidth,
  );
}
