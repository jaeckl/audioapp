part of 'arrangement_view.dart';

extension ArrangementViewStateTrackByIndexOperation on ArrangementViewState {
  /// Sentinel index for the virtual master row (`snapshot.tracks.length`).
  int get _masterTrackIndex => widget.snapshot.tracks.length;

  TrackSnapshot _masterTrackSnapshot() => widget.snapshot.master.asTrackSnapshot(
        projectAutomationClips: widget.snapshot.automationClips,
      );

  TrackSnapshot _trackByIndex(int index) {
    final tracks = widget.snapshot.tracks;
    if (index >= 0 && index < tracks.length) {
      return tracks[index];
    }
    return _masterTrackSnapshot();
  }
}
