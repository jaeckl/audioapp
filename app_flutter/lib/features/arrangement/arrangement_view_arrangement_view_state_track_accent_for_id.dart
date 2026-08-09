part of 'arrangement_view.dart';

extension ArrangementViewStateTrackAccentForIdOperation on ArrangementViewState {
  Color _trackAccentForId(String trackId) {
    if (trackId == 'master') return TrackLaneColor.master;
    final index =
        widget.snapshot.tracks.indexWhere((track) => track.id == trackId);
    if (index < 0) return TrackLaneColor.master;
    return TrackLaneColor.colorForTrack(widget.snapshot.tracks[index], index);
  }
}
