part of 'play_deck.dart';

extension PlayDeckStateSetsurfacemodeOperation on PlayDeckState {
void setSurfaceMode(PlaySurfaceMode mode) {
    if (_surfaceMode == mode) return;
    setState(() {
      _surfaceMode = mode;
      _view = PlayContextView.perform;
      _highlightedPitches.clear();
    });
  }
}
