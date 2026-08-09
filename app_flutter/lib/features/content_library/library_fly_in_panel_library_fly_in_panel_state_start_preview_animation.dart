part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateStartpreviewanimationOperation
    on LibraryFlyInPanelState {
  void _startPreviewAnimation({
    required double startBeat,
    required double lengthBeats,
    required int bpm,
    required bool loop,
  }) {
    _previewTicker?.cancel();
    _previewActive = true;
    _previewLoop = loop;
    _previewLengthBeats = lengthBeats > 0 ? lengthBeats : 4.0;
    _previewStartBeat = startBeat.clamp(0.0, _previewLengthBeats);
    _previewBpm = bpm <= 0 ? 120 : bpm;
    _previewStartedAt = DateTime.now();
    _presetScrubBeat = _previewStartBeat;

    _previewTicker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted || !_previewActive || _previewStartedAt == null) return;
      final elapsedMs =
          DateTime.now().difference(_previewStartedAt!).inMicroseconds /
              1000.0;
      final elapsedBeats = (elapsedMs / 1000.0) * (_previewBpm / 60.0);
      var beat = _previewStartBeat + elapsedBeats;
      if (_previewLoop) {
        // Walk 0..length, wrap to start of timeline (not mid-window).
        beat %= _previewLengthBeats;
      } else if (beat >= _previewLengthBeats) {
        beat = _previewLengthBeats;
        _previewActive = false;
        _previewTicker?.cancel();
        _previewTicker = null;
      }
      if (beat != _presetScrubBeat) {
        setState(() => _presetScrubBeat = beat);
      }
    });
  }
}
