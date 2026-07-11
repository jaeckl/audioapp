part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateStartpreviewplay on _PianoRollScreenState {
  Future<void> _startPreviewPlay() async {
    if (_previewTransport.isPlaying || _previewTransportCommandInFlight) return;
    _previewTransportCommandInFlight = true;
    try {
      final beat = _previewTransport.clipLocalBeat;
      await _previewTransport.play(bpm: widget.bpm);
      if (mounted) {
        _timelineScrollController.revealPlayheadAtViewportOrigin(beat);
      }
    } finally {
      _previewTransportCommandInFlight = false;
    }
  }
}
