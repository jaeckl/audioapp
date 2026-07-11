part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateWithmiditakesnapshot on _PianoRollScreenState {
  Future<void> _withMidiTakeSnapshot(
    Future<ProjectSnapshot> Function() action,
  ) async {
    final snapshot = await action();
    widget.onSnapshot(snapshot);
    if (!mounted) return;
    final refreshed = _findClipInSnapshot(snapshot, widget.clip.id);
    if (refreshed != null) {
      _applyRefreshedClip(refreshed);
    }
  }
}
