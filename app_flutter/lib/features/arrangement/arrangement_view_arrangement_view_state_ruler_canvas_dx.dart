part of 'arrangement_view.dart';

extension ArrangementViewStateRulercanvasdxOperation on ArrangementViewState {
double _rulerCanvasDx(PointerEvent event) {
    return event.localPosition.dx + _rulerScrollOffset;
  }
}
