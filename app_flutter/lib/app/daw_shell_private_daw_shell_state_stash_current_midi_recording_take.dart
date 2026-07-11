part of 'daw_shell.dart';

extension DawShellStateStashcurrentmidirecordingtakeOperation on _DawShellState {
void _stashCurrentMidiRecordingTake({required double endBeat}) {
    final notes = _currentMidiRecordingPreviewNotes(endBeat);
    if (notes.isNotEmpty) {
      _pendingMidiRecordingTakes.add(_PendingMidiRecordingTake(
        startBeat: _midiRecordingStartBeat,
        endBeat: endBeat,
        notes: notes,
      ));
    }
    final previewClipId = _midiRecordingPreviewClipId;
    if (previewClipId != null &&
        previewClipId.startsWith('midi-record-preview-')) {
      _liveClipStartBeats.remove(previewClipId);
    }
    _midiRecordingOpenNotes.clear();
    _midiRecordingPreviewNotes.clear();
  }
}
