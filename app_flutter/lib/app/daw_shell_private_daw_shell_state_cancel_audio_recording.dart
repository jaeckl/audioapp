part of 'daw_shell.dart';

extension DawShellStateCancelaudiorecordingOperation on _DawShellState {
Future<void> _cancelAudioRecording() async {
    if (!_anyRecordingActive) return;
    final sessions = List<AudioRecordingSession>.of(_audioRecordingSessions);
    final midiPreviewClipId = _midiRecordingPreviewClipId;
    final midiTargetClip = _midiRecordingTargetClip;
    final automationPreviewClipIds = _automationRecordingClipIds.values.toSet();
    final automationOriginalClips = Map<String, AutomationClipSnapshot>.of(
        _automationRecordingOriginalClips);
    _audioRecordingTrackId = null;
    _audioRecordingSampleId = null;
    _audioRecordingClipId = null;
    _midiRecordingTrackId = null;
    _midiRecordingPreviewClipId = null;
    _midiRecordingTargetClip = null;
    _midiRecordingOpenNotes.clear();
    _midiRecordingPreviewNotes.clear();
    _pendingMidiRecordingTakes.clear();
    _automationRecording.cancel();
    _automationRecordingClipIds.clear();
    _automationRecordingOriginalClips.clear();
    _audioRecordingSessions.clear();
    _lastAudioRecordingPlayhead = null;
    _audioRecordingInputLevel = 0.0;
    _highlightedClipId = null;
    _audioRecordingSnapshotTimer?.cancel();
    try {
      await widget.bridge.cancelMidiRecordingSession();
      ProjectSnapshot? lastSnapshot;
      if (midiPreviewClipId != null && midiTargetClip == null) {
        _liveClipStartBeats.remove(midiPreviewClipId);
      }
      for (final clipId in automationPreviewClipIds) {
        _liveClipStartBeats.remove(clipId);
        final original = automationOriginalClips[clipId];
        if (original != null) {
          lastSnapshot = await widget.bridge.setClipLength(
            clipId: clipId,
            lengthBeats: original.lengthBeats,
          );
          lastSnapshot = await widget.bridge.setAutomationPoints(
            clipId: clipId,
            points: original.points,
          );
        } else {
          lastSnapshot = await widget.bridge.deleteClip(clipId);
        }
      }
      if (sessions.isNotEmpty) {
        await widget.bridge.cancelTrackAudioRecording();
      }
      final cancelled = <String>{};
      for (final session in sessions.reversed) {
        final key = '${session.sampleId}:${session.clipId}';
        if (cancelled.contains(key)) continue;
        cancelled.add(key);
        _liveClipStartBeats.remove(session.clipId);
        lastSnapshot = await widget.bridge.cancelAudioRecordingSession(
          sampleId: session.sampleId,
          clipId: session.clipId,
        );
      }
      if (lastSnapshot != null) await _refreshSnapshot(lastSnapshot);
      await _transport.stopPlay();
      _liveMeters.clear();
      if (!mounted) return;
      setState(() {
        _saveStatus = 'Recording discarded';
        _projectError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
