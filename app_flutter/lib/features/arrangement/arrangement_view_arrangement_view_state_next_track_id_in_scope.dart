part of 'arrangement_view.dart';

extension ArrangementViewStateNexttrackidinscopeOperation on ArrangementViewState {
String _nextTrackIdInScope({
    required TrackSnapshot target,
    required String parentGroupId,
    required TrackSnapshot source,
  }) {
    var passedTarget = false;
    for (final candidate in widget.snapshot.tracks) {
      if (!passedTarget) {
        passedTarget = candidate.id == target.id;
        continue;
      }
      if (candidate.parentGroupId != parentGroupId) continue;
      if (candidate.id == source.id) continue;
      if (source.isGroup && candidate.parentGroupId == source.id) continue;
      return candidate.id;
    }
    return '';
  }
}
