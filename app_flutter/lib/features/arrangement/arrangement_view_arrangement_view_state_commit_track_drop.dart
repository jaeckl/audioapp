part of 'arrangement_view.dart';

extension ArrangementViewStateCommittrackdropOperation on ArrangementViewState {
Future<void> _commitTrackDrop(_TrackDropIntent intent) async {
    HapticFeedback.mediumImpact();
    await widget.onMoveTrack?.call(
      trackId: intent.trackId,
      parentGroupId: intent.parentGroupId,
      beforeTrackId: intent.beforeTrackId,
    );
  }
}
