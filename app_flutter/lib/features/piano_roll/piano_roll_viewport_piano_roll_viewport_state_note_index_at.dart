part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateNoteindexat on PianoRollViewportState {
  int? _noteIndexAt(Offset canvasPos) {
    for (var i = widget.notes.length - 1; i >= 0; i--) {
      final note = widget.notes[i];
      final top = _topForPitch(note.pitch);
      if (top == null) continue;
      final left = note.startBeat * _pixelsPerBeat;
      final width = note.durationBeats * _pixelsPerBeat;
      final rect = Rect.fromLTWH(left, top, width, _rowHeight);
      if (rect.contains(canvasPos)) return i;
    }
    return null;
  }
}
