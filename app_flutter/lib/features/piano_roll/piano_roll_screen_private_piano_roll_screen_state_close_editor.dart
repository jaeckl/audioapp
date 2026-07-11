part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateCloseeditor on _PianoRollScreenState {
  Future<void> _closeEditor() async {
    final pending = _pendingNoteSave;
    if (pending != null) {
      await pending;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
