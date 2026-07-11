part of 'arrangement_view.dart';

extension ArrangementViewStateScheduleplaybackfollowupdateOperation on ArrangementViewState {
void _schedulePlaybackFollowUpdate(ArrangementView oldWidget) {
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
        _followPlayheadIfNeeded(widget.playheadBeats, immediate: true);
        return;
      }
      final loopWrapped = timelinePlayheadLoopedBackward(
        oldBeat: oldWidget.playheadBeats,
        newBeat: widget.playheadBeats,
        loopEnabled: widget.snapshot.loopEnabled,
      );
      if (loopWrapped && widget.playing && widget.followPlayheadEnabled) {
        _resumeFollow();
        _lastFollowAnimateAt = null;
        _followPlayheadIfNeeded(widget.playheadBeats, immediate: true);
      } else if (widget.playing &&
          widget.followPlayheadEnabled &&
          !_followSuspended &&
          widget.playheadBeats != oldWidget.playheadBeats) {
        _followPlayheadIfNeeded(widget.playheadBeats, immediate: false);
      }
    });
  }
}
