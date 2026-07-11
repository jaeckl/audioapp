part of 'arrangement_view.dart';

extension ArrangementViewStateFollowplayheadifneededOperation on ArrangementViewState {
void _followPlayheadIfNeeded(double beat, {required bool immediate}) {
    if (!widget.followPlayheadEnabled || _followSuspended || !widget.playing) {
      return;
    }
    if (_timelineViewportWidth <= 0) {
      return;
    }
    if (!timelinePlayheadNeedsFollow(
      beat: beat,
      pixelsPerBeat: _pixelsPerBeat,
      scrollOffset: _horizontalScrollOffset,
      viewportWidth: _timelineViewportWidth,
    )) {
      return;
    }
    final leadX = timelineLeadViewportX(_timelineViewportWidth);
    if (immediate) {
      _jumpScrollToBeat(beat, viewportX: leadX);
      return;
    }
    final now = DateTime.now();
    if (_lastFollowAnimateAt != null &&
        now.difference(_lastFollowAnimateAt!) <
            ArrangementViewState._followAnimateMinInterval) {
      return;
    }
    _lastFollowAnimateAt = now;
    _animateScrollToBeat(beat, viewportX: leadX);
  }
}
