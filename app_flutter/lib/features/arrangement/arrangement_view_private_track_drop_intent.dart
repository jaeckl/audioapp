part of 'arrangement_view.dart';

class _TrackDropIntent {
  const _TrackDropIntent({
    required this.trackId,
    required this.parentGroupId,
    required this.beforeTrackId,
    required this.zone,
  });

  final String trackId;
  final String parentGroupId;
  final String beforeTrackId;
  final _TrackDropZone zone;

  @override
  bool operator ==(Object other) =>
      other is _TrackDropIntent &&
      other.trackId == trackId &&
      other.parentGroupId == parentGroupId &&
      other.beforeTrackId == beforeTrackId &&
      other.zone == zone;

  @override
  int get hashCode => Object.hash(trackId, parentGroupId, beforeTrackId, zone);
}
