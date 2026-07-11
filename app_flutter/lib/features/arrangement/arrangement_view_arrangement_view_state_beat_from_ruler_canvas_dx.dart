part of 'arrangement_view.dart';

extension ArrangementViewStateBeatfromrulercanvasdxOperation on ArrangementViewState {
double _beatFromRulerCanvasDx(double canvasDx) {
    return (canvasDx / _pixelsPerBeat).clamp(0.0, _timelineEndBeat);
  }
}
