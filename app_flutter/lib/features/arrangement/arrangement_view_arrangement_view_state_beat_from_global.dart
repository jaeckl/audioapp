part of 'arrangement_view.dart';

extension ArrangementViewStateBeatfromglobalOperation on ArrangementViewState {
double _beatFromGlobal(Offset globalPosition) {
    final viewport =
        _timelineViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) {
      return widget.playheadBeats;
    }
    final localX = viewport.globalToLocal(globalPosition).dx;
    final scrollX =
        _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
    return ((scrollX + localX) / _pixelsPerBeat).clamp(
      0.0,
      _timelineEndBeat,
    );
  }
}
