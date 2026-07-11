part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateDragmodeat on PianoRollViewportState {
  _DragMode _dragModeAt(Offset canvasPos, int index) {
    if (widget.laneLayout != null) return _DragMode.move;
    final note = widget.notes[index];
    final left = note.startBeat * _pixelsPerBeat;
    final width = note.durationBeats * _pixelsPerBeat;
    if (canvasPos.dx >= left + width - PianoRollMetrics.noteResizeHandle) {
      return _DragMode.resize;
    }
    return _DragMode.move;
  }
}
