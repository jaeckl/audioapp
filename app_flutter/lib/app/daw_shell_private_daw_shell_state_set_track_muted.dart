part of 'daw_shell.dart';

extension DawShellStateSettrackmutedOperation on _DawShellState {
Future<void> _setTrackMuted({
    required String trackId,
    required bool muted,
  }) async {
    _store.replaceSnapshot(
      _snapshot!.withTrackMix(trackId: trackId, muted: muted),
    );
    try {
      final snapshot = await widget.bridge.setTrackMuted(
        trackId: trackId,
        muted: muted,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
