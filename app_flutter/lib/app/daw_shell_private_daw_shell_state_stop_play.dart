part of 'daw_shell.dart';

extension DawShellStateStopplayOperation on _DawShellState {
Future<void> _stopPlay() async {
    final sessions = List<AudioRecordingSession>.of(_audioRecordingSessions);
    final clipId = _audioRecordingClipId;
    final automationEndBeat = _effectivePlayheadBeats;
    _audioRecordingTrackId = null;
    _audioRecordingSampleId = null;
    _audioRecordingClipId = null;
    _audioRecordingSessions.clear();
    _lastAudioRecordingPlayhead = null;
    _audioRecordingInputLevel = 0.0;
    _audioRecordingSnapshotTimer?.cancel();
    await _transport.stopPlay();
    _liveMeters.clear();
    try {
      final midiSnapshot =
          await _finishMidiRecordingSession(endBeat: automationEndBeat);
      if (midiSnapshot != null) await _refreshSnapshot(midiSnapshot);
      final automationSnapshot = await _finishAutomationRecordingSegment(
        endBeat: automationEndBeat,
        keepSessionActive: false,
      );
      if (automationSnapshot != null) {
        await _refreshSnapshot(automationSnapshot);
      }
    } catch (e) {
      if (mounted) setState(() => _projectError = e.toString());
    }
    if (sessions.isNotEmpty) {
      try {
        await widget.bridge.stopTrackAudioRecording();
        ProjectSnapshot? lastSnapshot;
        final finished = <String>{};
        for (final session in sessions) {
          final key = '${session.sampleId}:${session.clipId}';
          if (finished.contains(key)) continue;
          finished.add(key);
          _liveClipStartBeats.remove(session.clipId);
          lastSnapshot = await widget.bridge.finishAudioRecordingSession(
            sampleId: session.sampleId,
            clipId: session.clipId,
          );
        }
        if (lastSnapshot != null) await _refreshSnapshot(lastSnapshot);
        _highlightedClipId = clipId;
        _arrangementScrollController.revealPlayheadAtViewportOrigin(
          _audioRecordingStartBeat,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _projectError = e.toString());
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }
}
