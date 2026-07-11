part of 'daw_shell.dart';

extension DawShellStateToggletrackfreezeOperation on _DawShellState {
Future<void> _toggleTrackFreeze({
    required String trackId,
    required bool enabled,
    required bool stale,
  }) async {
    final wasPlaying = _snapshot?.playing ?? false;
    if (wasPlaying) {
      await widget.bridge.stop();
    }
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
    } finally {
      if (wasPlaying && mounted) {
        await widget.bridge.play();
      }
    }
  }
}
