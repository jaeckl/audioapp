part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateDeleteselected on _PianoRollScreenState {
  void _deleteSelected() {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _notes.length) return;
    final notes = List<MidiNoteSnapshot>.of(_notes)..removeAt(index);
    _applyNotes(notes, selectedIndex: null);
  }
}
