part of 'arrangement_view.dart';

extension ArrangementViewStateCliploopcontentOperation on ArrangementViewState {
bool? _clipLoopContent(String clipId) {
    for (final track in widget.snapshot.tracks) {
      for (final clip in track.midiClips) {
        if (clip.id == clipId) {
          return clip.loopContent;
        }
      }
      for (final clip in track.sampleClips) {
        if (clip.id == clipId) {
          return clip.loopContent;
        }
      }
    }
    for (final clip in widget.snapshot.automationClips) {
      if (clip.id == clipId) {
        return clip.loopContent;
      }
    }
    return null;
  }
}
