part of 'daw_shell.dart';

extension DawShellStateFinishmidirecordingsessionOperation on _DawShellState {
Future<ProjectSnapshot?> _finishMidiRecordingSession(
      {double? endBeat}) async {
    final trackId = _midiRecordingTrackId;
    if (trackId == null) return null;
    final previewClipId = _midiRecordingPreviewClipId;
    final targetClip = _midiRecordingTargetClip;
    final finishBeat = endBeat ?? _effectivePlayheadBeats;
    final recordedNotes = _currentMidiRecordingPreviewNotes(finishBeat);
    final takePasses = [
      ..._pendingMidiRecordingTakes,
      if (recordedNotes.isNotEmpty)
        _PendingMidiRecordingTake(
          startBeat: _midiRecordingStartBeat,
          endBeat: finishBeat,
          notes: recordedNotes,
        ),
    ];
    _pendingMidiRecordingTakes.clear();
    _midiRecordingTrackId = null;
    _midiRecordingPreviewClipId = null;
    _midiRecordingTargetClip = null;
    _midiRecordingOpenNotes.clear();
    _midiRecordingPreviewNotes.clear();
    if (previewClipId != null) {
      _liveClipStartBeats.remove(previewClipId);
    }
    try {
      if (_recordWriteMode == RecordWriteMode.take && takePasses.isEmpty) {
        await widget.bridge.cancelMidiRecordingSession();
        return null;
      }
      if (targetClip != null) {
        await widget.bridge.cancelMidiRecordingSession();
        if (_recordWriteMode == RecordWriteMode.take) {
          ProjectSnapshot? snapshot;
          for (final entry in takePasses.indexed) {
            final pass = entry.$2;
            snapshot = await widget.bridge.addMidiClipTake(
              clipId: targetClip.id,
              name: 'Take ${targetClip.takes.length + 1 + entry.$1}',
              startBeatOffset: (pass.startBeat - targetClip.startBeat)
                  .clamp(0.0, targetClip.lengthBeats)
                  .toDouble(),
              lengthBeats: pass.lengthBeats,
              notes: pass.notes,
            );
          }
          _highlightedClipId = targetClip.id;
          return snapshot;
        }
        var snapshot = await widget.bridge.setMidiClipNotes(
          clipId: targetClip.id,
          notes: mergeMidiRecordingNotes(
            existingNotes: targetClip.notes,
            recordedNotes: recordedNotes,
            targetClipStartBeat: targetClip.startBeat,
            recordingStartBeat: _midiRecordingStartBeat,
            recordingEndBeat: finishBeat,
            mode: _recordWriteMode,
          ),
        );
        final requiredLength = (finishBeat - targetClip.startBeat)
            .clamp(targetClip.lengthBeats, 1024.0)
            .toDouble();
        if (requiredLength > targetClip.lengthBeats + 0.001) {
          snapshot = await widget.bridge.setClipLength(
            clipId: targetClip.id,
            lengthBeats: requiredLength,
          );
        }
        return snapshot;
      }
      if (_recordWriteMode == RecordWriteMode.take) {
        await widget.bridge.cancelMidiRecordingSession();
        final created = await _createMidiTakeAnchorClip(
          trackId: trackId,
          finishBeat: finishBeat,
          firstPass: takePasses.first,
        );
        var snapshot = created.snapshot;
        for (var i = 1; i < takePasses.length; i++) {
          final pass = takePasses[i];
          snapshot = await widget.bridge.addMidiClipTake(
            clipId: created.clipId,
            name: 'Take ${i + 1}',
            startBeatOffset: (pass.startBeat - created.anchorStartBeat)
                .clamp(0.0, created.anchorLengthBeats)
                .toDouble(),
            lengthBeats: pass.lengthBeats,
            notes: pass.notes,
          );
        }
        return snapshot;
      }
      var snapshot =
          await widget.bridge.finishMidiRecordingSession(endBeat: endBeat);
      return snapshot;
    } catch (_) {
      return null;
    }
  }
}
