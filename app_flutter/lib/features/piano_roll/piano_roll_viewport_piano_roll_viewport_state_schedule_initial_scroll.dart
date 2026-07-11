part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateScheduleinitialscroll
    on PianoRollViewportState {
  void _scheduleInitialScroll(double viewportHeight) {
    if (_didInitialScroll) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitialScroll) return;
      if (!_vertical.hasClients) return;
      _didInitialScroll = true;
      final y = widget.laneLayout != null
          ? 0.0
          : PianoRollMetrics.initialVerticalScrollOffset(
              pitches: widget.drumAnchorPitch != null && widget.notes.isEmpty
                  ? [widget.drumAnchorPitch!]
                  : widget.notes.map((n) => n.pitch),
              minPitch: widget.minPitch,
              maxPitch: widget.maxPitch,
              rowHeight: _rowHeight,
              viewportHeight: viewportHeight,
            );
      _vertical.jumpTo(y);
      if (_verticalKeys.hasClients) _verticalKeys.jumpTo(y);
      if (_horizontal.hasClients) _horizontal.jumpTo(0);
      if (_ruler.hasClients) _ruler.jumpTo(0);
      _emitCenterOctave();
    });
  }
}
