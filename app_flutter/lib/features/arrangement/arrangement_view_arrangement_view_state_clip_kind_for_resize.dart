part of 'arrangement_view.dart';

extension ArrangementViewStateClipkindforresizeOperation on ArrangementViewState {
ClipContentKind _clipKindForResize(String clipId) {
    for (final track in widget.snapshot.tracks) {
      for (final c in track.midiClips) {
        if (c.id == clipId) return ClipContentKind.midi;
      }
      for (final c in track.sampleClips) {
        if (c.id == clipId) return ClipContentKind.sample;
      }
      for (final c in track.automationClips) {
        if (c.id == clipId) return ClipContentKind.automation;
      }
    }
    return ClipContentKind.midi;
  }
}
