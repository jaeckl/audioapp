part of 'piano_roll_screen.dart';

extension _PianoRollScreenStatePushundo on _PianoRollScreenState {
  void _pushUndo() {
    _undoStack.add(_cloneNotes(_notes));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }
}
