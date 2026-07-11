part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateOneditstarted on _PianoRollScreenState {
  void _onEditStarted() {
    setState(_pushUndo);
    if (_needsCompFlatten && !_showTakes) {
      unawaited(_ensureCompFlattened(showToast: true));
    }
  }
}
