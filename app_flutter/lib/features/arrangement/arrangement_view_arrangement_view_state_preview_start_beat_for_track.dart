part of 'arrangement_view.dart';

extension ArrangementViewStatePreviewstartbeatfortrackOperation on ArrangementViewState {
double _previewStartBeatForTrack(
    TrackSnapshot track,
    ArrangementClipDragSession session,
    double desiredBeat,
  ) {
    return ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: desiredBeat,
      clipLengthBeats: session.lengthBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrackExcluding(
        track,
        excludeClipId: session.clipId,
      ),
      timelineEndBeats: _timelineEndBeat,
      grid: _snapGridBeats,
      snapStartToGrid: widget.snapClipsEnabled,
    );
  }
}
