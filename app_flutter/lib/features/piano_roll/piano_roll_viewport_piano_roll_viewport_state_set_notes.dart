part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateSetnotes on PianoRollViewportState {
  void _setNotes(List<MidiNoteSnapshot> notes) {
    widget.onNotesChanged(notes);
  }
}
