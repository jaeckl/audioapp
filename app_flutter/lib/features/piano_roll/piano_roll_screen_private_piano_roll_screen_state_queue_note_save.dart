part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateQueuenotesave on _PianoRollScreenState {
  void _queueNoteSave() {
    _pendingNoteSave = _persistNotes();
  }
}
