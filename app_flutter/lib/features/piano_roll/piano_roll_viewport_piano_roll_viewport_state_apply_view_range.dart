part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateApplyviewrange on PianoRollViewportState {
  void _applyViewRange(int bars) {
    if (_scrollViewportWidth <= 0) return;
    final ppb =
        EditorViewRange.pixelsPerBeatForWidth(_scrollViewportWidth, bars);
    setState(() {
      _pixelsPerBeat = ppb;
      _appliedViewRangeBeats = bars;
    });
    _jumpScrollToStart();
  }
}
