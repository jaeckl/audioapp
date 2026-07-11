part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateOnnoteschanged on _PianoRollScreenState {
  void _onNotesChanged(List<MidiNoteSnapshot> notes) {
    setState(() => _notes = notes);
  }
}
