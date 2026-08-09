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
    final takeAccent = activeTakeId == null
        ? null
        : MidiTakeColor.forTakeId(activeTakeId, widget.takes);
    final laneBorder = takeAccent != null
        ? MidiTakeColor.laneAccentBorder(
            takeAccent,
            highlighted: isWinningLane,
          )
        : Colors.white.withValues(alpha: 0.08);
    final laneFill = takeAccent != null
        ? MidiTakeColor.laneAccentFill(
            takeAccent,
            highlighted: isWinningLane,
          )
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
                takes: widget.takes,
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
