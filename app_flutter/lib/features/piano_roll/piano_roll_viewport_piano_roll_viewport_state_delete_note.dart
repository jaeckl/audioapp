part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateDeletenote on PianoRollViewportState {
  void _deleteNote(int index) {
    widget.onEditStarted();
    final notes = List<MidiNoteSnapshot>.of(widget.notes)..removeAt(index);
    _setNotes(notes);
    widget.onSelectionChanged(null);
    widget.onEditFinished();
  }
}
