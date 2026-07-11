part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateFindclipinsnapshotOperation on _SampleEditorScreenState {
SampleClipSnapshot? _findClipInSnapshot(ProjectSnapshot snapshot, String id) {
    for (final track in snapshot.tracks) {
      for (final clip in track.sampleClips) {
        if (clip.id == id) return clip;
      }
    }
    return null;
  }
}
