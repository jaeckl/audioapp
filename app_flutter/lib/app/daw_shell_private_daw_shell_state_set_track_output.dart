part of 'daw_shell.dart';

extension DawShellStateSettrackoutputOperation on _DawShellState {
  Future<void> _setTrackOutput({
    required String trackId,
    required String outputTarget,
  }) async {
    try {
      final snapshot = await widget.bridge.setTrackOutput(
        trackId: trackId,
        outputTarget: outputTarget,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
