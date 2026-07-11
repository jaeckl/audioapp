part of 'daw_shell.dart';

extension DawShellStateAddautomationclipOperation on _DawShellState {
Future<void> _addAutomationClip(
    String trackId,
    double startBeat, {
    String? deviceId,
    String? paramId,
  }) async {
    if (_trackFrozen(trackId)) {
      _showFrozenTrackSnack();
      return;
    }
    try {
      await widget.bridge.selectTrack(trackId);
      final beforeIds =
          _snapshot?.automationClips.map((c) => c.id).toSet() ?? <String>{};
      var snapshot = await widget.bridge.createAutomationClip(
        trackId: trackId,
        startBeat: startBeat,
      );
      // Automation clips are project-global; the new one is the last entry
      // in the top-level array (regardless of which track it ended up on).
      final newClips = snapshot.automationClips
          .where((c) => !beforeIds.contains(c.id))
          .toList();
      if (newClips.isEmpty) {
        await _refreshSnapshot(snapshot);
        return;
      }
      final created = newClips.last;
      if (deviceId != null && paramId != null) {
        snapshot = await widget.bridge.assignAutomationTarget(
          clipId: created.id,
          deviceId: deviceId,
          paramId: paramId,
        );
      }
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
