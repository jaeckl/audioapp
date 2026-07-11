part of 'daw_shell.dart';

extension DawShellStateSettrackrecordarmedOperation on _DawShellState {
Future<void> _setTrackRecordArmed({
    required String trackId,
    required bool armed,
  }) async {
    try {
      if (armed) {
        await widget.bridge.ensureRecordAudioPermission();
      }
      if (_snapshot?.selectedTrackId != trackId) {
        await _applyDeltaMutation('selectTrack', {'trackId': trackId});
      }
      await _store.invokeRaw('setRecordArmed', {'armed': armed});
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
