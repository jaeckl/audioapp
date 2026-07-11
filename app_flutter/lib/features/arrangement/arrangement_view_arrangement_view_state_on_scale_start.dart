part of 'arrangement_view.dart';

extension ArrangementViewStateOnscalestartOperation on ArrangementViewState {
void _onScaleStart(ScaleStartDetails details) {
    _scaleStartPixelsPerBeat = _pixelsPerBeat;
    if (widget.followPlayheadEnabled && widget.playing) {
      _suspendFollow();
    }
  }
}
