part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateComputepreviewlengthbeatsOperation
    on LibraryFlyInPanelState {
  double _computePreviewLengthBeats() {
    final loopEnd = widget.snapshot.loopRegionEndBeat;
    final trackId = widget.snapshot.selectedTrackId;
    for (final t in widget.snapshot.tracks) {
      if (t.id != trackId) continue;
      return libraryPresetPreviewLengthBeats(
        t.midiClips,
        loopRegionEndBeat: loopEnd,
      );
    }
    return loopEnd > 4.0 ? loopEnd : 4.0;
  }
}
