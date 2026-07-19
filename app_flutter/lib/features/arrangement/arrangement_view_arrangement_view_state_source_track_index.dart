part of 'arrangement_view.dart';

extension ArrangementViewStateSourcetrackindexOperation on ArrangementViewState {
  int _sourceTrackIndex(String trackId) {
    if (trackId == 'master') {
      return _masterTrackIndex;
    }
    final tracks = widget.snapshot.tracks;
    for (var i = 0; i < tracks.length; i++) {
      if (tracks[i].id == trackId) {
        return i;
      }
    }
    return 0;
  }
}
