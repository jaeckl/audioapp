part of 'daw_shell.dart';

extension DawShellStateBeginmidirecordingpassOperation on _DawShellState {
Future<void> _beginMidiRecordingPass({
    required String trackId,
    required double startBeat,
    ProjectSnapshot? snapshot,
  }) async {
    await widget.bridge.beginMidiRecordingSession(
      trackId: trackId,
      startBeat: startBeat,
      quantizeStep: 0.25,
    );
    _midiRecordingTrackId = trackId;
    _midiRecordingStartBeat = startBeat;
    _midiRecordingOpenNotes.clear();
    _midiRecordingPreviewNotes.clear();
    _midiRecordingTargetClip = _midiRecordingTargetForMode(
      trackId,
      startBeat,
      snapshot: snapshot,
    );
    if (_midiRecordingTargetClip case final target?) {
      _midiRecordingPreviewClipId = target.id;
      _highlightedClipId = target.id;
    } else {
      await _createMidiRecordingPreviewClip(trackId, startBeat);
    }
  }
}
