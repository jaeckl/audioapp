part of 'daw_shell.dart';

extension DawShellStateRolllooprecordingifneededOperation on _DawShellState {
Future<void> _rollLoopRecordingIfNeeded(TransportState transport) async {
    if (_audioRecordingRollBusy ||
        !_anyRecordingActive ||
        transport.loopEnabled != true ||
        transport.loopRegionEndBeat <= transport.loopRegionStartBeat) {
      _lastAudioRecordingPlayhead = transport.playheadBeats;
      return;
    }
    final last = _lastAudioRecordingPlayhead;
    final current = transport.playheadBeats;
    final didWrap = last != null && current + 0.25 < last;
    _lastAudioRecordingPlayhead = current;
    if (!didWrap) return;

    final loopStart = transport.loopRegionStartBeat;
    if (_midiRecordingActive) {
      final trackId = _midiRecordingTrackId;
      final targetSnapshot = _snapshot;
      if (trackId != null) {
        try {
          if (_recordWriteMode == RecordWriteMode.take) {
            _stashCurrentMidiRecordingTake(
                endBeat: transport.loopRegionEndBeat);
            await widget.bridge.cancelMidiRecordingSession();
          } else {
            final committedSnapshot = await _finishMidiRecordingSession(
                endBeat: transport.loopRegionEndBeat);
            if (committedSnapshot != null) {
              await _refreshSnapshot(committedSnapshot);
            }
          }
          await _beginMidiRecordingPass(
            trackId: trackId,
            startBeat: loopStart,
            snapshot: targetSnapshot,
          );
        } catch (e) {
          _midiRecordingTrackId = null;
          if (mounted) {
            setState(() => _projectError = 'MIDI take restart failed: $e');
          }
        }
      }
    }
    if (_automationRecordingActive) {
      await _finishAutomationRecordingSegment(
        endBeat: transport.loopRegionEndBeat,
        keepSessionActive: true,
        nextStartBeat: loopStart,
      );
      for (final clipId in _automationRecordingClipIds.values) {
        _liveClipStartBeats.remove(clipId);
      }
      _automationRecordingClipIds.clear();
    }

    final trackId = _audioRecordingTrackId;
    final oldSampleId = _audioRecordingSampleId;
    final clipId = _audioRecordingClipId;
    if (trackId == null || oldSampleId == null || clipId == null) return;

    _audioRecordingRollBusy = true;
    try {
      final displayName =
          'Recorded take ${DateTime.now().millisecondsSinceEpoch}';
      final nextSession = await widget.bridge.beginAudioRecordingSession(
        trackId: trackId,
        startBeat: loopStart,
        sampleRate: 48000,
        displayName: displayName,
        targetClipId: clipId,
      );
      if (nextSession.sampleId.isEmpty || nextSession.clipId.isEmpty) return;
      await widget.bridge.retargetTrackAudioRecording(
        sampleId: nextSession.sampleId,
        clipId: nextSession.clipId,
      );
      final snapshot = await widget.bridge.finishAudioRecordingSession(
        sampleId: oldSampleId,
        clipId: clipId,
      );
      await _refreshSnapshot(snapshot);
      _audioRecordingSampleId = nextSession.sampleId;
      _audioRecordingClipId = nextSession.clipId;
      _audioRecordingStartBeat = loopStart;
      _audioRecordingSessions.add(nextSession);
      _highlightedClipId = nextSession.clipId;
      _liveClipStartBeats[nextSession.clipId] = loopStart;
      if (mounted) setState(() {});
    } finally {
      _audioRecordingRollBusy = false;
    }
  }
}
