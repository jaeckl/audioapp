part of 'arrangement_playhead_marker.dart';

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
        onPointerDown: (event) =>
            onPointerDown(event, _canvasDx(event.localPosition.dx)),
        onPointerMove: (event) =>
            onPointerMove(event, _canvasDx(event.localPosition.dx)),
        onPointerUp: (event) =>
            onPointerUp(event, _canvasDx(event.localPosition.dx)),
        onPointerCancel: (event) =>
            onPointerUp(event, _canvasDx(event.localPosition.dx)),
        child: const SizedBox.expand(),
      ),
    );
  }
}
