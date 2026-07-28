part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateEnsurearrangementcoverscontent
    on _PianoRollScreenState {
  /// One-shot clips: engine gates MIDI by arrangement [lengthBeats]. Growing
  /// content alone leaves notes past the old span silent — grow arrangement too.
  Future<ProjectSnapshot> _ensureArrangementCoversContent(
    ProjectSnapshot snapshot,
  ) async {
    final clip = _findClipInSnapshot(snapshot, widget.clip.id);
    if (clip == null || clip.loopContent) return snapshot;
    final content = clip.editorContentLengthBeats;
    if (content <= clip.lengthBeats + 1e-9) return snapshot;
    return widget.bridge.setClipLength(
      clipId: clip.id,
      lengthBeats: content,
      target: ClipLengthTarget.arrangement,
    );
  }
}
