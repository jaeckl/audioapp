part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateApplynotes on _PianoRollScreenState {
  void _applyNotes(List<MidiNoteSnapshot> notes, {int? selectedIndex}) {
    setState(() {
      _pushUndo();
      _notes = notes;
      _selectedIndex = selectedIndex;
    });
    _queueNoteSave();
  }
}
