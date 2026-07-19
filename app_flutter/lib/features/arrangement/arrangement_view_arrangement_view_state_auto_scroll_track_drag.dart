part of 'arrangement_view.dart';

extension ArrangementViewStateAutoscrolltrackdragOperation on ArrangementViewState {
void _autoScrollTrackDrag(DragUpdateDetails details) {
    if (!_trackVerticalScroll.hasClients) return;
    final stack =
        _arrangementStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null) return;
    final localY = stack.globalToLocal(details.globalPosition).dy;
    final viewportTop = PianoRollMetrics.rulerHeight;
    final viewportBottom = stack.size.height;
    const edgeSize = 52.0;
    double delta = 0;
    if (localY < viewportTop + edgeSize) {
      delta = -18;
    } else if (localY > viewportBottom - edgeSize) {
      delta = 18;
    }
    if (delta == 0) return;
    final target = (_trackVerticalScroll.offset + delta).clamp(
      0.0,
      _trackVerticalScroll.position.maxScrollExtent,
    );
    if (target != _trackVerticalScroll.offset) {
      _trackVerticalScroll.jumpTo(target);
    }
  }
}
