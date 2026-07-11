part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateNudgeselectedtakemarkerOperation on _SampleEditorScreenState {
void _nudgeSelectedTakeMarker(int direction) {
    final index = selectedTakeMarker;
    final markers = _takeMarkerBeats;
    if (index == null || index < 0 || index >= markers.length) return;
    final step = editSnap.snap == SampleEditSnap.off
        ? 0.125
        : math.max(0.125, editSnap.snap.sourceStep * widget.clip.lengthBeats);
    final next = markers[index] + direction * step;
    _moveTakeMarker(index, next);
    unawaited(_saveTakeMarkerMove(index, next));
  }
}
