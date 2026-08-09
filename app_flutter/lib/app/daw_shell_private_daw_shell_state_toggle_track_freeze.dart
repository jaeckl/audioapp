part of 'daw_shell.dart';

extension DawShellStateToggletrackfreezeOperation on _DawShellState {
Future<void> _toggleTrackFreeze({
    required String trackId,
    required bool enabled,
    required bool stale,
  }) async {
    // Engine bakes off the project lock; keep transport running.
    try {
      final ProjectSnapshot snapshot;
      if (enabled && stale) {
        snapshot = await widget.bridge.refreshTrackFreeze(trackId);
      } else if (enabled) {
        snapshot = await widget.bridge.unfreezeTrack(trackId);
      } else {
        snapshot = await widget.bridge.freezeTrack(trackId);
      }
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
