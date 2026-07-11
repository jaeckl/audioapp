part of 'daw_shell.dart';

extension DawShellStateSettracksoloedOperation on _DawShellState {
Future<void> _setTrackSoloed({
    required String trackId,
    required bool soloed,
  }) async {
    _store.replaceSnapshot(
      _snapshot!.withTrackMix(trackId: trackId, soloed: soloed),
    );
    try {
      final snapshot = await widget.bridge.setTrackSoloed(
        trackId: trackId,
        soloed: soloed,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
