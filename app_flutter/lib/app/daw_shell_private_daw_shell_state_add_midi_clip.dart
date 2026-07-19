part of 'daw_shell.dart';

extension DawShellStateAddmidiclipOperation on _DawShellState {
  Future<void> _addMidiClip(String trackId, double startBeat) async {
    if (_trackFrozen(trackId)) {
      _showFrozenTrackSnack();
      return;
    }
    try {
      await widget.bridge.selectTrack(trackId);
      final beforeClipCount = _trackById(trackId)?.midiClips.length ?? 0;
      final snapshot = await widget.bridge.createMidiClip(
        trackId: trackId,
        startBeat: startBeat,
      );
      final track = snapshot.trackById(trackId);
      if (track != null && track.midiClips.length <= beforeClipCount) {
        return;
      }
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
