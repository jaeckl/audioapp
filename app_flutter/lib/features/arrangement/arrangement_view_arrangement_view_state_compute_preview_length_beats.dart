part of 'arrangement_view.dart';

extension ArrangementViewStateComputepreviewlengthbeatsOperation on ArrangementViewState {
double _computePreviewLengthBeats(
    double currentPointerBeat,
    _ClipResizeSession session,
    double minLength,
  ) {
    final delta = currentPointerBeat - session.pointerBeatAtStart;
    final rawLength = session.originalLengthBeats + delta;
    final upper = session.maxLengthBeats;
    final clamped = upper.isFinite
        ? rawLength.clamp(minLength, upper)
        : (rawLength < minLength ? minLength : rawLength);
    if (!widget.snapClipsEnabled) {
      return clamped.toDouble();
    }
    final snappedEnd = ArrangementTimelineMetrics.quantizeBeat(
      session.startBeat + clamped,
      grid: _snapGridBeats,
    );
    final snappedLength = snappedEnd - session.startBeat;
    final snappedUpper = upper.isFinite ? upper : double.infinity;
    return snappedLength.clamp(minLength, snappedUpper).toDouble();
  }
}
