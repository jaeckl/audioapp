part of 'daw_shell.dart';

extension DawShellStateOnlibraryautomationtapOperation on _DawShellState {
Future<void> _onLibraryAutomationTap(LibraryAutomationItem item) async {
    final track = _snapshot?.selectedTrack;
    if (track == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a track first')),
      );
      return;
    }

    if (item.trackId != null && item.clip != null) {
      await _openAutomationCurveEditor(item.trackId!, item.clip!);
      await _libraryPanelKey.currentState?.close();
      return;
    }

    final startBeat = ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: _effectivePlayheadBeats,
      clipLengthBeats: ArrangementTimelineMetrics.defaultMidiClipLengthBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
    );

    String? deviceId;
    String? paramId;
    if (item.suggestedParamId != null) {
      final DeviceSnapshot? synth =
          track.subtractiveSynthDevice ?? track.samplerDevice;
      if (synth != null) {
        deviceId = synth.id;
        paramId = item.suggestedParamId;
      }
    }

    await _addAutomationClip(
      track.id,
      startBeat,
      deviceId: deviceId,
      paramId: paramId,
    );
    await _libraryPanelKey.currentState?.close();
  }
}
