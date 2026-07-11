part of 'daw_shell.dart';

extension DawShellStateInsertsampleOperation on _DawShellState {
Future<void> _insertSample(SampleLibraryEntrySnapshot sample) async {
    final trackId = _snapshot?.selectedTrackId;
    if (trackId == null || trackId.isEmpty) return;
    if (_trackFrozen(trackId)) {
      _showFrozenTrackSnack();
      return;
    }
    try {
      final updated = await widget.bridge.createSampleClip(
        trackId: trackId,
        sampleId: sample.id,
      );
      await _refreshSnapshot(updated);
      if (!mounted) return;
      setState(() => _tab = _ShellTab.devices);
      await _libraryPanelKey.currentState?.close();
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
