part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateDragmodeat on PianoRollViewportState {
  _DragMode _dragModeAt(
    Offset canvasPos,
    int index, {
    bool asChord = false,
  }) {
    if (widget.laneLayout != null) return _DragMode.move;
    final handle = PianoRollMetrics.noteResizeHandle;
    final useGroup = asChord ||
        (widget.chordGroupEdit && widget.chordGroupSelected);

    late final double left;
    late final double width;
    if (useGroup) {
      final group = _chordGroupFor(index);
      var minStart = double.infinity;
      var maxEnd = 0.0;
      for (final i in group) {
        final n = widget.notes[i];
        if (n.startBeat < minStart) minStart = n.startBeat;
        final end = n.startBeat + n.durationBeats;
        if (end > maxEnd) maxEnd = end;
      }
      left = minStart * _pixelsPerBeat;
      width = (maxEnd - minStart) * _pixelsPerBeat;
    } else {
      final note = widget.notes[index];
      left = note.startBeat * _pixelsPerBeat;
      width = note.durationBeats * _pixelsPerBeat;
    }

    final distRight = (left + width) - canvasPos.dx;
    final distLeft = canvasPos.dx - left;
    if (distRight <= handle && distRight <= distLeft) {
      return _DragMode.resizeEnd;
    }
    if (distLeft <= handle) {
      return _DragMode.resizeStart;
    }
    return _DragMode.move;
  }
}
