part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateUpdatenote on PianoRollViewportState {
  void _updateNote(int index, MidiNoteSnapshot note) {
    final notes = List<MidiNoteSnapshot>.of(widget.notes);
    notes[index] = note;
    _setNotes(notes);
  }
}
