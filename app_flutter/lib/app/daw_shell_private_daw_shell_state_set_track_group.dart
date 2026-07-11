part of 'daw_shell.dart';

extension DawShellStateSettrackgroupOperation on _DawShellState {
Future<void> _setTrackGroup(String trackId, String? groupTrackId) async {
    try {
      final snapshot = await widget.bridge.setTrackGroup(
        trackId: trackId,
        groupTrackId: groupTrackId ?? '',
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
