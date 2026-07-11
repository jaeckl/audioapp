part of 'daw_shell.dart';

extension DawShellStateMovetrackOperation on _DawShellState {
Future<void> _moveTrack({
    required String trackId,
    required String parentGroupId,
    required String beforeTrackId,
  }) async {
    try {
      final snapshot = await widget.bridge.moveTrack(
        trackId: trackId,
        parentGroupId: parentGroupId,
        beforeTrackId: beforeTrackId,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
