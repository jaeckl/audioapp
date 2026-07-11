part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateComputepreviewlengthbeatsOperation on LibraryFlyInPanelState {
double _computePreviewLengthBeats() {
    // Mirror the logic in daw_shell._onLibraryPresetPreviewTap: longest MIDI
    // clip on the selected track, with a 4-beat minimum so an empty track
    // still animates something visible.
    const minBeats = 4.0;
    final trackId = widget.snapshot.selectedTrackId;
    for (final t in widget.snapshot.tracks) {
      if (t.id != trackId) continue;
      double max = 0;
      for (final clip in t.midiClips) {
        final end = clip.startBeat + clip.lengthBeats;
        if (end > max) max = end;
      }
      return max > minBeats ? max : minBeats;
    }
    return minBeats;
  }
}
