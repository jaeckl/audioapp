part of 'midi_take_comp_view.dart';

extension _MidiTakeCompViewStateLane on _MidiTakeCompViewState {
  Widget _lane({
    required double top,
    required List<MidiNoteSnapshot> notes,
    required List<int> pitchRows,
    required String? activeTakeId,
    ValueChanged<double>? onTapBeat,
  }) {
    final compMode = widget.compTool == MidiCompTool.comp;
    final winningTake = _takeIdAtPlayhead;
    final isWinningLane =
        compMode && activeTakeId != null && activeTakeId == winningTake;
    final isCompLane = compMode && activeTakeId != null;
    final laneBorder = isWinningLane
        ? ArrangementLoopRegionTheme.color.withValues(alpha: 0.72)
        : isCompLane
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.052);
    final laneFill = isWinningLane
        ? ArrangementLoopRegionTheme.color.withValues(alpha: 0.12)
        : isCompLane
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.018);
    return Positioned(
      left: 0,
      top: top,
      width: _timelineWidth,
      height: _laneHeight,
      child: EditorBeatTapSurface(
        pixelsPerBeat: _pixelsPerBeat,
        maxBeat: widget.clipLengthBeats,
        enabled: onTapBeat != null && !_pinchInteracting,
        onBeat: onTapBeat ?? (_) {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: laneFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: laneBorder,
              width: isWinningLane ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              painter: _MidiTakeLanePainter(
                notes: notes,
                regions: widget.regions,
                activeTakeId: activeTakeId,
                pitchRows: pitchRows,
                clipLengthBeats: widget.clipLengthBeats,
                virtualLengthBeats: widget.virtualLengthBeats,
                notesTop: _MidiTakeCompViewState._laneTopChrome,
                pixelsPerBeat: _pixelsPerBeat,
                pitchRowHeight: _MidiTakeCompViewState._pitchRowHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
