part of 'arrangement_view.dart';

extension ArrangementViewStateScheduleplaybackfollowstatechangeOperation on ArrangementViewState {
void _schedulePlaybackFollowStateChange(ArrangementView oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.playing && oldWidget.playing) {
        _cancelFollowScroll();
        return;
      }
      if (widget.playing &&
          !oldWidget.playing &&
          widget.followPlayheadEnabled) {
        _resumeFollow();
      }
      if (widget.followPlayheadEnabled &&
          !oldWidget.followPlayheadEnabled &&
          widget.playing) {
        _resumeFollow();
        final beat = widget.playheadListenable?.value ?? widget.playheadBeats;
        _followPlayheadIfNeeded(beat, immediate: true);
      }
    });
  }
}
