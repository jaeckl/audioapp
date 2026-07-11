part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateQuantizeselection on _PianoRollScreenState {
  void _quantizeSelection() {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _notes.length) return;
    final notes = List<MidiNoteSnapshot>.of(_notes);
    notes[index] = PianoRollNoteOps.quantize(
      notes[index],
      _grid,
      maxLengthBeats: _clipLengthBeats,
    );
    _applyNotes(notes, selectedIndex: index);
  }
}
