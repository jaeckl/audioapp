part of 'arrangement_view.dart';

extension ArrangementViewStateVisibletracksOperation on ArrangementViewState {
List<TrackSnapshot> _visibleTracks() {
    if (widget.compact) {
      return widget.snapshot.tracks
          .where((track) =>
              track.id ==
              (widget.focusTrackId ?? widget.snapshot.selectedTrackId))
          .toList();
    }
    return widget.snapshot.tracks.where((track) {
      return track.parentGroupId.isEmpty ||
          !_collapsedGroupIds.contains(track.parentGroupId);
    }).toList();
  }
}
