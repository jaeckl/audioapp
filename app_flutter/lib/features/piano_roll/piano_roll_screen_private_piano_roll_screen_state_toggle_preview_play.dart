part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateTogglepreviewplay on _PianoRollScreenState {
  Future<void> _togglePreviewPlay() async {
    if (_previewTransport.isPlaying) {
      await _stopPreviewPlay();
    } else {
      await _startPreviewPlay();
    }
  }
}
