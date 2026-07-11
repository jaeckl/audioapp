part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateRedo on _PianoRollScreenState {
  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_cloneNotes(_notes));
    setState(() => _notes = _redoStack.removeLast());
    _queueNoteSave();
  }
}
