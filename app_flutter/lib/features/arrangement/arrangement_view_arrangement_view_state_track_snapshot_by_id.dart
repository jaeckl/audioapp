part of 'arrangement_view.dart';

extension ArrangementViewStateTracksnapshotbyidOperation on ArrangementViewState {
  TrackSnapshot? _trackSnapshotById(String id) {
    if (id == 'master') {
      return _masterTrackSnapshot();
    }
    for (final track in widget.snapshot.tracks) {
      if (track.id == id) return track;
    }
    return null;
  }
}
