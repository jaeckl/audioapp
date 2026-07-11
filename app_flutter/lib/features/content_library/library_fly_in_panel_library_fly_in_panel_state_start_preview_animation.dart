part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateStartpreviewanimationOperation on LibraryFlyInPanelState {
void _startPreviewAnimation({
    required double startBeat,
    required double lengthBeats,
    required int bpm,
    required bool loop,
  }) {
    _previewTicker?.cancel();
    _previewActive = true;
    _previewLoop = loop;
    _previewLengthBeats = lengthBeats;
    _previewStartBeat = startBeat;
    _previewBpm = bpm <= 0 ? 120 : bpm;
    _previewStartedAt = DateTime.now();
    _presetScrubBeat = startBeat;

    _previewTicker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted || !_previewActive || _previewStartedAt == null) return;
      final elapsedMs = DateTime.now().difference(_previewStartedAt!).inMicroseconds / 1000.0;
      final elapsedBeats = (elapsedMs / 1000.0) * (_previewBpm / 60.0);
      double beat = _previewStartBeat + elapsedBeats;
      if (_previewLoop && _previewLengthBeats > 0) {
        beat = beat % _previewLengthBeats;
      } else if (beat >= _previewLengthBeats) {
        beat = _previewLengthBeats;
        _previewActive = false;
      }
      if (beat != _presetScrubBeat) {
        setState(() => _presetScrubBeat = beat);
      }
    });
  }
}
