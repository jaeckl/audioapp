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
    final laneH = ArrangementTimelineMetrics.trackLaneHeight;
    final tracksEnd = visibleTracks.length * laneH;
    final addEnd = tracksEnd + (widget.compact ? 0.0 : laneH);
    final masterStart = addEnd + _masterLaneGap;

    if (visibleTracks.isNotEmpty && localY < tracksEnd) {
      final laneIndex =
          (localY ~/ laneH).clamp(0, visibleTracks.length - 1);
      final trackId = visibleTracks[laneIndex].id;
      final snapshotIndex =
          widget.snapshot.tracks.indexWhere((track) => track.id == trackId);
      return snapshotIndex < 0 ? 0 : snapshotIndex;
    }

    if (!widget.compact && localY < addEnd) {
      // Add-track chrome — snap to last real lane.
      if (visibleTracks.isEmpty) return _masterTrackIndex;
      final id = visibleTracks.last.id;
      final snapshotIndex =
          widget.snapshot.tracks.indexWhere((track) => track.id == id);
      return snapshotIndex < 0 ? 0 : snapshotIndex;
    }

    // Gap above master, or master lane itself.
    if (!widget.compact && localY >= masterStart - _masterLaneGap) {
      return _masterTrackIndex;
    }

    if (visibleTracks.isEmpty) return _masterTrackIndex;
    final id = visibleTracks.last.id;
    final snapshotIndex =
        widget.snapshot.tracks.indexWhere((track) => track.id == id);
    return snapshotIndex < 0 ? 0 : snapshotIndex;
  }
}
