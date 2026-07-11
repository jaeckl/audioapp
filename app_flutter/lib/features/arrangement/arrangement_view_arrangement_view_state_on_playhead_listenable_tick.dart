part of 'arrangement_view.dart';

extension ArrangementViewStateOnplayheadlistenabletickOperation on ArrangementViewState {
void _onPlayheadListenableTick() {
    if (!mounted ||
        widget.playheadListenable == null ||
        _scrubPlayheadBeats != null) {
      return;
    }
    final beat = widget.playheadListenable!.value;
    if (widget.liveClipStartBeats.isNotEmpty) {
      setState(() {});
    }
    final oldBeat = _lastListenedPlayheadBeat;
    _lastListenedPlayheadBeat = beat;
    if (oldBeat == null) return;

    if (!widget.playing) return;

    final loopWrapped = timelinePlayheadLoopedBackward(
      oldBeat: oldBeat,
      newBeat: beat,
      loopEnabled: widget.snapshot.loopEnabled,
    );
    if (loopWrapped && widget.followPlayheadEnabled) {
      _resumeFollow();
      _lastFollowAnimateAt = null;
      _followPlayheadIfNeeded(beat, immediate: true);
      return;
    }
    if (widget.followPlayheadEnabled && !_followSuspended) {
      _followPlayheadIfNeeded(beat, immediate: false);
    }
  }
}
