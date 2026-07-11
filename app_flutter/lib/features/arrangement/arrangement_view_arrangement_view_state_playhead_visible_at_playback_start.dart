part of 'arrangement_view.dart';

extension ArrangementViewStatePlayheadvisibleatplaybackstartOperation on ArrangementViewState {
bool _playheadVisibleAtPlaybackStart(double beat) {
    if (_timelineViewportWidth <= 0) {
      return true;
    }
    final natural = timelineNaturalViewportX(
      beat: beat,
      pixelsPerBeat: _pixelsPerBeat,
      scrollOffset: _horizontalScrollOffset,
    );
    if (natural <= 0) {
      return true;
    }
    final leadX = timelineLeadViewportX(_timelineViewportWidth);
    final maxX =
        _timelineViewportWidth * TimelineFollowMetrics.maxVisibleFraction;
    return natural >= leadX && natural <= maxX;
  }
}
