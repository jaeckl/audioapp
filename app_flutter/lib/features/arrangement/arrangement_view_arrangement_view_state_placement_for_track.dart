part of 'arrangement_view.dart';

extension ArrangementViewStatePlacementfortrackOperation on ArrangementViewState {
double _placementForTrack(
      TrackSnapshot track, double desiredBeat, double clipLengthBeats) {
    return ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: desiredBeat,
      clipLengthBeats: clipLengthBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
    );
  }
}
