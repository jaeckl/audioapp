part of 'arrangement_view.dart';

extension ArrangementViewStateOnrulerpointerdownOperation on ArrangementViewState {
void _onRulerPointerDown(PointerDownEvent event) {
    final canvasDx = _rulerCanvasDx(event);
    _rulerActivePointer = event.pointer;
    _rulerLastCanvasPos = Offset(canvasDx, event.localPosition.dy);
    _rulerPointerTravel = 0;

    final start = _displayRegionStart;
    final end = _displayRegionEnd;
    if (_hitPlayheadMarker(canvasDx)) {
      _rulerDragTarget = _RulerDragTarget.playhead;
    } else if (_hitRegionMarker(canvasDx, end)) {
      _rulerDragTarget = _RulerDragTarget.regionEnd;
    } else if (_hitRegionMarker(canvasDx, start)) {
      _rulerDragTarget = _RulerDragTarget.regionStart;
    } else {
      _rulerDragTarget = null;
    }
    setState(() {});
  }
}
