part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateUndo on _PianoRollScreenState {
  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_cloneNotes(_notes));
    setState(() => _notes = _undoStack.removeLast());
    _queueNoteSave();
  }
}
