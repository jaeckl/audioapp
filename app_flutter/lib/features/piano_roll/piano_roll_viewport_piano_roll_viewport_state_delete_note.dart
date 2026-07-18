part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateDeletenote on PianoRollViewportState {
  void _deleteNote(int index) {
    widget.onEditStarted();
    final notes = List<MidiNoteSnapshot>.of(widget.notes)..removeAt(index);
    _setNotes(notes);
    widget.onSelectionChanged(null);
    widget.onChordGroupSelectedChanged?.call(true);
    widget.onEditFinished();
  }

  void _deleteChordGroup(int primaryIndex) {
    widget.onEditStarted();
    final group = _chordGroupFor(primaryIndex).toSet();
    final notes = [
      for (var i = 0; i < widget.notes.length; i++)
        if (!group.contains(i)) widget.notes[i],
    ];
    _setNotes(notes);
    widget.onSelectionChanged(null);
    widget.onChordGroupSelectedChanged?.call(true);
    widget.onEditFinished();
  }
}
