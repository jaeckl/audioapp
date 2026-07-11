part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateOnpresetpreviewtapOperation on LibraryFlyInPanelState {
void _onPresetPreviewTap(LibraryPresetItem item, {double? startBeat, bool? loop}) {
    final effectiveStart = startBeat ?? _presetScrubBeat;
    final effectiveLoop = loop ?? _presetPreviewLoopEnabled;
    if (startBeat != null) {
      _presetScrubBeat = startBeat;
    }

    // Start the visual playhead animation so the bar shows the head moving.
    // Use the project's BPM and a 4-bar default length (matches the C-arpeggio
    // fallback used in daw_shell._onLibraryPresetPreviewTap).
    final bpm = widget.snapshot.bpm;
    final lengthBeats = _computePreviewLengthBeats();
    setState(() {
      _startPreviewAnimation(
        startBeat: effectiveStart,
        lengthBeats: lengthBeats,
        bpm: bpm,
        loop: effectiveLoop,
      );
    });

    widget.onPresetPreviewTap?.call(item, startBeat: effectiveStart, loop: effectiveLoop);
  }
}
