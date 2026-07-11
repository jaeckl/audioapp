part of 'daw_shell.dart';

extension DawShellStateUpdateliverecordingpreviewsOperation on _DawShellState {
Future<void> _updateLiveRecordingPreviews(TransportState transport) async {
    if (_midiRecordingActive) {
      await _updateMidiRecordingPreview(transport.playheadBeats);
    }
    if (_automationRecordingActive) {
      await _updateAutomationRecordingPreviews(transport.playheadBeats);
    }
  }
}
