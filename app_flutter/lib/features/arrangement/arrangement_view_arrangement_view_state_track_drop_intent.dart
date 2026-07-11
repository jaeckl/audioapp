part of 'arrangement_view.dart';

extension ArrangementViewStateTrackdropintentOperation on ArrangementViewState {
_TrackDropIntent? _trackDropIntent(
    _TrackDragData data,
    TrackSnapshot target,
    _TrackDropZone zone,
  ) {
    final source = data.track;
    if (widget.onMoveTrack == null || source.id == target.id) return null;
    if (source.isGroup && target.parentGroupId == source.id) return null;

    if (source.isGroup) {
      final topLevelTarget = target.parentGroupId.isEmpty
          ? target
          : _trackSnapshotById(target.parentGroupId);
      if (topLevelTarget == null || topLevelTarget.id == source.id) return null;
      final insertBefore = zone == _TrackDropZone.before
          ? topLevelTarget.id
          : _nextTrackIdInScope(
              target: topLevelTarget,
              parentGroupId: '',
              source: source,
            );
      return _TrackDropIntent(
        trackId: source.id,
        parentGroupId: '',
        beforeTrackId: insertBefore,
        zone: zone == _TrackDropZone.before
            ? _TrackDropZone.before
            : _TrackDropZone.after,
      );
    }

    if (target.isGroup && zone == _TrackDropZone.inside) {
      return _TrackDropIntent(
        trackId: source.id,
        parentGroupId: target.id,
        beforeTrackId: '',
        zone: _TrackDropZone.inside,
      );
    }

    final parentGroupId = target.parentGroupId;
    final insertBefore = zone == _TrackDropZone.before
        ? target.id
        : _nextTrackIdInScope(
            target: target,
            parentGroupId: parentGroupId,
            source: source,
          );
    return _TrackDropIntent(
      trackId: source.id,
      parentGroupId: parentGroupId,
      beforeTrackId: insertBefore,
      zone: zone == _TrackDropZone.before
          ? _TrackDropZone.before
          : _TrackDropZone.after,
    );
  }
}
