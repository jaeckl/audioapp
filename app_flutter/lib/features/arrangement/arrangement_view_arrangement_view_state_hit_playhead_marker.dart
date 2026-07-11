part of 'arrangement_view.dart';

extension ArrangementViewStateHitplayheadmarkerOperation on ArrangementViewState {
bool _hitPlayheadMarker(double canvasDx) {
    return hitArrangementPlayheadMarker(
      canvasDx: canvasDx,
      markerBeat: _displayPlayheadBeats,
      pixelsPerBeat: _pixelsPerBeat,
      scrollOffset: _rulerScrollOffset,
      playing: widget.playing,
    );
  }
}
