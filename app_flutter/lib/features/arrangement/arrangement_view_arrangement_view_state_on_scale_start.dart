part of 'arrangement_view.dart';

extension ArrangementViewStateOnscalestartOperation on ArrangementViewState {
void _onScaleStart(ScaleStartDetails details) {
    _scaleStartPixelsPerBeat = _pixelsPerBeat;
    final scrollX =
        _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
    _scaleStartFocalX = details.focalPoint.dx;
    _scaleStartBeatAtFocal =
        (scrollX + _scaleStartFocalX) / _pixelsPerBeat;
    if (widget.followPlayheadEnabled && widget.playing) {
      _suspendFollow();
    }
  }
}
