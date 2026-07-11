part of 'daw_shell.dart';

extension DawShellStateActivateprojectOperation on _DawShellState {
Future<void> _activateProject(ProjectSnapshot snapshot) async {
    snapshot = await _registerDemoSamples(snapshot);
    await widget.bridge.enterPlayMode();
    await _refreshSnapshot(snapshot);
    _transport.syncTransportAnchorFromSnapshot(
      snapshot.bpm,
      snapshot.loopEnabled,
      snapshot.loopRegionStartBeat,
      snapshot.loopRegionEndBeat,
      snapshot.playheadBeats,
    );
    if (!mounted) return;
    setState(() {
      _tab = _ShellTab.devices;
      _projectError = null;
    });
  }
}
