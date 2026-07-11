part of 'arrangement_view.dart';

extension ArrangementViewStateMayberesolvependingresizeOperation on ArrangementViewState {
void _maybeResolvePendingResize() {
    final session = _resizeSession;
    if (session == null || !session.committed) return;
    final expected = session.previewLengthBeats;
    final actual = _lengthBeatsForClip(session.clipId);
    if (actual == null) {
      // Clip was removed (e.g. deleted). Drop the session.
      setState(() => _resizeSession = null);
      return;
    }
    if ((actual - expected).abs() < 1e-6) {
      setState(() => _resizeSession = null);
    }
  }
}
