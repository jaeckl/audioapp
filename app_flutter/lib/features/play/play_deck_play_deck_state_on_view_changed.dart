part of 'play_deck.dart';

extension PlayDeckStateOnviewchangedOperation on PlayDeckState {
void _onViewChanged(PlayContextView view) {
    setState(() {
      _view = view;
      if (view != PlayContextView.performPanel) {
        _highlightedPitches.clear();
      }
    });
    _notifyChrome();
  }
}
