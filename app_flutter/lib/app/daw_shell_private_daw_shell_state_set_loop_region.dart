part of 'daw_shell.dart';

extension DawShellStateSetloopregionOperation on _DawShellState {
Future<void> _setLoopRegion({
    required double startBeat,
    required double endBeat,
  }) async {
    try {
      await _applyDeltaMutation('setLoopRegion', {
        'startBeat': startBeat,
        'endBeat': endBeat,
      });
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
