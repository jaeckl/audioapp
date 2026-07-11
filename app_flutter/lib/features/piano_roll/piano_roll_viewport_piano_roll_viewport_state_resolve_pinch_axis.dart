part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateResolvepinchaxis on PianoRollViewportState {
  _PinchZoomAxis _resolvePinchAxis(double spanX, double spanY) {
    if (spanX >= spanY * PianoRollViewportState._pinchAxisRatio) {
      return _PinchZoomAxis.horizontal;
    }
    if (spanY >= spanX * PianoRollViewportState._pinchAxisRatio) {
      return _PinchZoomAxis.vertical;
    }
    return spanX >= spanY ? _PinchZoomAxis.horizontal : _PinchZoomAxis.vertical;
  }
}
