part of 'play_deck.dart';

extension PlayDeckStateUpdatehighlightsOperation on PlayDeckState {
void _updateHighlights(int rootOffset) {
    _activeRootOffset = rootOffset;
    if (_chord == ChordQuality.off) {
      _highlightedPitches
        ..clear()
        ..add(_rootMidi + _octaveOffset * 12 + rootOffset);
      return;
    }
    final root = _rootMidi + _octaveOffset * 12 + rootOffset;
    _highlightedPitches
      ..clear()
      ..addAll(
        PlayDeckStateBuildchordpitchesOperation._buildChordPitches(
          root,
          _chord,
          _octaveSpan,
        ),
      );
  }
}
