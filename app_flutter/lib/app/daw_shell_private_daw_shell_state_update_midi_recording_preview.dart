part of 'daw_shell.dart';

extension DawShellStateUpdatemidirecordingpreviewOperation on _DawShellState {
Future<void> _updateMidiRecordingPreview(double endBeat) async {
    final clipId = _midiRecordingPreviewClipId;
    if (clipId == null) return;
    if (mounted) setState(() {});
  }
}
