part of 'arrangement_view.dart';

extension ArrangementViewStateLengthbeatsforclipOperation on ArrangementViewState {
double? _lengthBeatsForClip(String clipId) {
    for (final track in widget.snapshot.tracks) {
      for (final c in track.midiClips) {
        if (c.id == clipId) return c.lengthBeats;
      }
      for (final c in track.sampleClips) {
        if (c.id == clipId) return c.lengthBeats;
      }
      for (final c in track.automationClips) {
        if (c.id == clipId) return c.lengthBeats;
      }
    }
    return null;
  }
}
