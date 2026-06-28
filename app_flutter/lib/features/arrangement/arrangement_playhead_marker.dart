import 'package:flutter/material.dart';

import '../editor/timeline_marker_layer.dart';

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
    hitWidth: ArrangementPlayheadMarkerTheme.effectiveHitWidth(playing: playing),
  );
}

/// Transparent touch layer aligned with the playhead pill (not [IgnorePointer]).
class ArrangementPlayheadHitTarget extends StatelessWidget {
  const ArrangementPlayheadHitTarget({
    super.key,
    required this.sideColumnWidth,
    required this.playheadDisplayX,
    required this.rulerHeight,
    required this.scrollOffset,
    required this.playing,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
  });

  final double sideColumnWidth;
  final double playheadDisplayX;
  final double rulerHeight;
  final double scrollOffset;
  final bool playing;
  final void Function(PointerDownEvent event, double canvasDx) onPointerDown;
  final void Function(PointerMoveEvent event, double canvasDx) onPointerMove;
  final void Function(PointerEvent event, double canvasDx) onPointerUp;

  double get _hitWidth =>
      ArrangementPlayheadMarkerTheme.effectiveHitWidth(playing: playing);

  double _canvasDx(double localDx) =>
      scrollOffset + playheadDisplayX - _hitWidth / 2 + localDx;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: sideColumnWidth + playheadDisplayX - _hitWidth / 2,
      top: TimelineMarkerLayerMetrics.overlayTop(),
      width: _hitWidth,
      height: ArrangementPlayheadMarkerTheme.hitLayerHeight(
        rulerHeight: rulerHeight,
        playing: playing,
      ),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) => onPointerDown(event, _canvasDx(event.localPosition.dx)),
        onPointerMove: (event) => onPointerMove(event, _canvasDx(event.localPosition.dx)),
        onPointerUp: (event) => onPointerUp(event, _canvasDx(event.localPosition.dx)),
        onPointerCancel: (event) => onPointerUp(event, _canvasDx(event.localPosition.dx)),
        child: const SizedBox.expand(),
      ),
    );
  }
}
