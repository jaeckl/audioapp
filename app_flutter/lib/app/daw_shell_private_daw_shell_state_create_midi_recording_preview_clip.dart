part of 'daw_shell.dart';

extension DawShellStateCreatemidirecordingpreviewclipOperation on _DawShellState {
Future<void> _createMidiRecordingPreviewClip(
    String trackId,
    double startBeat,
  ) async {
    _midiRecordingPreviewClipId =
        'midi-record-preview-${DateTime.now().microsecondsSinceEpoch}';
    _highlightedClipId = _midiRecordingPreviewClipId;
    _liveClipStartBeats[_midiRecordingPreviewClipId!] = startBeat;
    if (mounted) setState(() {});
  }
}
