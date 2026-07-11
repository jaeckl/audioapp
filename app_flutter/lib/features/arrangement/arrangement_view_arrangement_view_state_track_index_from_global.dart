part of 'arrangement_view.dart';

extension ArrangementViewStateTrackindexfromglobalOperation on ArrangementViewState {
int _trackIndexFromGlobal(Offset globalPosition) {
    final lanesBox =
        _trackLanesKey.currentContext?.findRenderObject() as RenderBox?;
    if (lanesBox == null) {
      return 0;
    }
    final localY = lanesBox.globalToLocal(globalPosition).dy;
    if (localY < 0) {
      return 0;
    }
    final visibleTracks = _visibleTracks();
    if (visibleTracks.isEmpty) return 0;
    final visibleIndex = (localY ~/ ArrangementTimelineMetrics.trackLaneHeight)
        .clamp(0, visibleTracks.length - 1);
    final trackId = visibleTracks[visibleIndex].id;
    final snapshotIndex =
        widget.snapshot.tracks.indexWhere((track) => track.id == trackId);
    return snapshotIndex < 0 ? 0 : snapshotIndex;
  }
}
