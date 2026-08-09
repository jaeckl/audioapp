part of 'play_deck.dart';

extension PlayDeckStateOnsurfacemodechangedOperation on PlayDeckState {
void _onSurfaceModeChanged(PlaySurfaceMode mode) {
    setState(() {
      _surfaceMode = mode;
      _view = PlayContextView.perform;
      _highlightedPitches.clear();
    });
    _notifyChrome();
  }
}
