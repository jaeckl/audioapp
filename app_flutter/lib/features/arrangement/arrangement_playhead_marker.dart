import 'package:flutter/material.dart';

import '../editor/timeline_marker_layer.dart';

part 'arrangement_playhead_marker_arrangement_playhead_hit_target.dart';

/// Arrangement playhead handle on the beat ruler (larger than loop region pills).
abstract final class ArrangementPlayheadMarkerTheme {
  static const double pillSize = 30;

  /// Horizontal touch slop beyond the visible pill (ruler hit test + hit layer).
  static const double hitWidth = 56;

  /// Wider target while playing — stop tap is harder on a moving/scrolling timeline.
  static const double hitWidthPlaying = 88;

  /// Extra invisible height below the ruler band during playback only.
  static const double hitExtendBelowRulerPlaying = 44;

  static double effectiveHitWidth({required bool playing}) =>
      playing ? hitWidthPlaying : hitWidth;

  static double hitLayerHeight({
    required double rulerHeight,
    required bool playing,
  }) {
    final base = TimelineMarkerLayerMetrics.overlayHeight(rulerHeight);
    return playing ? base + hitExtendBelowRulerPlaying : base;
  }
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
  required bool playing,
}) {
  return hitTimelineStickyPlayheadMarker(
    canvasDx: canvasDx,
    markerBeat: markerBeat,
    pixelsPerBeat: pixelsPerBeat,
    scrollOffset: scrollOffset,
    hitWidth:
        ArrangementPlayheadMarkerTheme.effectiveHitWidth(playing: playing),
  );
}

/// Transparent touch layer aligned with the playhead pill (not [IgnorePointer]).
