part of 'arrangement_view.dart';

extension ArrangementViewStateEndclipresizeOperation on ArrangementViewState {
void _endClipResize(DragEndDetails details) {
    final session = _resizeSession;
    if (session == null) return;
    final finalLength = session.previewLengthBeats;
    // Mark the session as committed but keep it alive. The handle stays at
    // the preview x so the UI does not snap back to the old clip end while
    // we wait for the engine snapshot to return. The session is cleared in
    // didUpdateWidget once the new lengthBeats has propagated through.
    setState(() => session.committed = true);
    if (widget.followPlayheadEnabled && widget.playing) {
      _resumeFollow();
    }
    final commit = widget.onResizeClipCommit;
    if (commit != null) {
      unawaited(commit(clipId: session.clipId, lengthBeats: finalLength));
    }
  }
}
