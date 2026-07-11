part of 'arrangement_view.dart';

extension ArrangementViewStateRevealplayheadatviewportoriginOperation on ArrangementViewState {
void _revealPlayheadAtViewportOrigin(double beat) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!timelinePlayheadIsSticky(
        beat: beat,
        pixelsPerBeat: _pixelsPerBeat,
        scrollOffset: _horizontalScrollOffset,
      )) {
        return;
      }
      _jumpScrollToBeat(beat, viewportX: 0);
    });
  }
}
