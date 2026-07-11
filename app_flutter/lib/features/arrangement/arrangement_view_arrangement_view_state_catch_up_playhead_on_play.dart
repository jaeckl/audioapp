part of 'arrangement_view.dart';

extension ArrangementViewStateCatchupplayheadonplayOperation on ArrangementViewState {
void _catchUpPlayheadOnPlay(double beat, {required bool immediate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.followPlayheadEnabled) {
        _resumeFollow();
        if (!_playheadVisibleAtPlaybackStart(beat)) {
          _followPlayheadIfNeeded(beat, immediate: immediate);
        }
        return;
      }
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
