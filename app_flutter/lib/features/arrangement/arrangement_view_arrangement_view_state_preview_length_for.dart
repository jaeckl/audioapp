part of 'arrangement_view.dart';

extension ArrangementViewStatePreviewlengthforOperation on ArrangementViewState {
double? previewLengthFor(String clipId) {
    final session = _resizeSession;
    if (session != null && session.clipId == clipId) {
      return session.previewLengthBeats;
    }
    final liveStart = widget.liveClipStartBeats[clipId];
    if (liveStart == null) return null;
    final playhead = widget.playheadListenable?.value ?? widget.playheadBeats;
    return (playhead - liveStart).clamp(0.25, 1024.0).toDouble();
  }
}
