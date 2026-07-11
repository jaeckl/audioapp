part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateQuantizeall on _PianoRollScreenState {
  void _quantizeAll() {
    final notes = PianoRollNoteOps.quantizeAll(
      _notes,
      _grid,
      maxLengthBeats: _clipLengthBeats,
    );
    _applyNotes(notes, selectedIndex: _selectedIndex);
  }
}
