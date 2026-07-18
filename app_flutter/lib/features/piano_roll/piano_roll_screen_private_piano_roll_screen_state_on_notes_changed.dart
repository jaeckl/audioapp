part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateOnnoteschanged on _PianoRollScreenState {
  void _onNotesChanged(List<MidiNoteSnapshot> notes) {
    setState(() {
      _notes = notes;
      _chordSlots = HarmonicNoteOps.pruneSlots(_chordSlots, notes);
      if (_chordSlots.isEmpty && notes.isNotEmpty) {
        _chordSlots = HarmonicNoteOps.slotsFromNotes(notes);
      }
    });
  }
}
