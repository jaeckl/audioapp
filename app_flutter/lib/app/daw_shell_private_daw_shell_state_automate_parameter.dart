part of 'daw_shell.dart';

extension DawShellStateAutomateparameterOperation on _DawShellState {
Future<void> _automateParameter(String deviceId, String paramId) async {
    final linkedClips = _snapshot?.automationClips
            .where(
                (clip) => clip.deviceId == deviceId && clip.paramId == paramId)
            .toList() ??
        const <AutomationClipSnapshot>[];
    if (linkedClips.isNotEmpty) {
      try {
        ProjectSnapshot? updated;
        for (final clip in linkedClips) {
          updated = await widget.bridge.unlinkAutomationTarget(clipId: clip.id);
        }
        if (updated != null) await _refreshSnapshot(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Automation unlinked from ${AutomationClipSnapshot.linkLabelForParam(paramId)}',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _projectError = e.toString());
      }
      return;
    }

    final track = _snapshot?.selectedTrack;
    if (track == null) return;

    DeviceSnapshot? device;
    for (final candidate in track.devices) {
      if (candidate.id == deviceId) {
        device = candidate;
        break;
      }
    }
    if (device == null) return;

    const lengthBeats = ArrangementTimelineMetrics.defaultMidiClipLengthBeats;
    final startBeat = ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: _effectivePlayheadBeats,
      clipLengthBeats: lengthBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
    );
    final value = _automationValueForDevice(device, paramId);

    try {
      await widget.bridge.selectTrack(track.id);
      final beforeIds =
          _snapshot?.automationClips.map((c) => c.id).toSet() ?? <String>{};
      var snapshot = await widget.bridge.createAutomationClip(
        trackId: track.id,
        startBeat: startBeat,
        lengthBeats: lengthBeats,
      );
      final newClips = snapshot.automationClips
          .where((c) => !beforeIds.contains(c.id))
          .toList();
      if (newClips.isEmpty) {
        await _refreshSnapshot(snapshot);
        return;
      }
      final created = newClips.last;
      snapshot = await widget.bridge.assignAutomationTarget(
        clipId: created.id,
        deviceId: deviceId,
        paramId: paramId,
      );
      snapshot = await widget.bridge.setAutomationPoints(
        clipId: created.id,
        points: [
          AutomationPointSnapshot(beat: 0, value: value),
          AutomationPointSnapshot(beat: lengthBeats, value: value),
        ],
      );
      await _refreshSnapshot(snapshot);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Automation clip for ${AutomationClipSnapshot.linkLabelForParam(paramId)}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
