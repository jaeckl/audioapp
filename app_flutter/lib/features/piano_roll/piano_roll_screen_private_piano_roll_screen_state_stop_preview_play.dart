part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateStoppreviewplay on _PianoRollScreenState {
  Future<void> _stopPreviewPlay() async {
    if (!_previewTransport.isPlaying || _previewTransportCommandInFlight) {
      return;
    }
    _previewTransportCommandInFlight = true;
    try {
      await _previewTransport.stop();
    } finally {
      _previewTransportCommandInFlight = false;
    }
  }
}
