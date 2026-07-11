part of 'arrangement_view.dart';

extension ArrangementViewStateOnplayheadhitpointerdownOperation on ArrangementViewState {
void _onPlayheadHitPointerDown(PointerDownEvent event, double canvasDx) {
    _rulerActivePointer = event.pointer;
    _rulerLastCanvasPos = Offset(canvasDx, 0);
    _rulerPointerTravel = 0;
    _rulerDragTarget = _RulerDragTarget.playhead;
    setState(() {});
  }
}
