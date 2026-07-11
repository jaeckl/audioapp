part of 'arrangement_view.dart';

extension ArrangementViewStateUpdateclipresizeOperation on ArrangementViewState {
void _updateClipResize(DragUpdateDetails details) {
    final session = _resizeSession;
    if (session == null) return;
    final pointerBeat = _beatFromGlobal(details.globalPosition);
    // Resize min length depends on clip kind — we stored kind implicitly via
    // originalLengthBeats and the clip id; lookup the actual kind below.
    final kind = _clipKindForResize(session.clipId);
    final minLength = _resizeMinLengthForKind(kind);
    final preview = _computePreviewLengthBeats(pointerBeat, session, minLength);
    setState(() => session.previewLengthBeats = preview);
  }
}
