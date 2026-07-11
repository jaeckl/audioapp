part of 'daw_shell.dart';

extension DawShellStateSetloopenabledOperation on _DawShellState {
Future<void> _setLoopEnabled(bool enabled) async {
    try {
      await _applyDeltaMutation('setLoopEnabled', {'enabled': enabled});
      _transport.syncTransportAnchorFromSnapshot(
        _snapshot!.bpm,
        _snapshot!.loopEnabled,
        _snapshot!.loopRegionStartBeat,
        _snapshot!.loopRegionEndBeat,
        _snapshot!.playheadBeats,
      );
      if (_transport.playing) {
        await _transport.syncTransportState();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
