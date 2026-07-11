part of 'daw_shell.dart';

extension DawShellStateBeginrecordingaftercountinOperation on _DawShellState {
Future<void> _beginRecordingAfterCountIn(
    String trackId,
    double requestedStartBeat, {
    required bool recordAudio,
    required bool recordMidi,
    required bool recordAutomation,
  }) async {
    try {
      var startBeat = requestedStartBeat;
      if (_countInBars > 0) {
        startBeat = await _waitForCountInToFinish(requestedStartBeat);
      }
      if (!_transport.playing || _snapshot?.selectedTrackId != trackId) return;

      if (recordMidi) {
        _pendingMidiRecordingTakes.clear();
        await _beginMidiRecordingPass(trackId: trackId, startBeat: startBeat);
      }

      if (recordAutomation) {
        _automationRecording.begin(trackId: trackId, startBeat: startBeat);
        _automationRecordingClipIds.clear();
        _automationRecordingOriginalClips.clear();
      }

      if (recordAudio) {
        final displayName =
            'Recorded take ${DateTime.now().millisecondsSinceEpoch}';
        final targetClipId = _recordingTargetClipId(trackId, startBeat);
        final session = await widget.bridge.beginAudioRecordingSession(
          trackId: trackId,
          startBeat: startBeat,
          sampleRate: 48000,
          displayName: displayName,
          targetClipId: targetClipId,
        );
        if (session.sampleId.isEmpty || session.clipId.isEmpty) {
          throw Exception('Recording session did not return ids');
        }
        await _refreshSnapshot(session.snapshot);
        try {
          await widget.bridge.startTrackAudioRecording(
            sampleId: session.sampleId,
            clipId: session.clipId,
          );
        } catch (_) {
          final snapshot = await widget.bridge.cancelAudioRecordingSession(
            sampleId: session.sampleId,
            clipId: session.clipId,
          );
          await _refreshSnapshot(snapshot);
          rethrow;
        }
        _audioRecordingTrackId = trackId;
        _audioRecordingSampleId = session.sampleId;
        _audioRecordingClipId = session.clipId;
        _audioRecordingStartBeat = startBeat;
        _audioRecordingSessions
          ..clear()
          ..add(session);
        _highlightedClipId = session.clipId;
        _liveClipStartBeats[session.clipId] = startBeat;
      }

      if (_anyRecordingActive) {
        _lastAudioRecordingPlayhead = startBeat;
        _arrangementScrollController.revealPlayheadAtViewportOrigin(startBeat);
        _startAudioRecordingSnapshotRefresh();
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (recordMidi) {
        try {
          await widget.bridge.cancelMidiRecordingSession();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
