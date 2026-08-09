/// Display order for tracks: each top-level track, then its group children
/// (preserving relative child order from [tracks]).
List<T> nestTracksUnderGroups<T>({
  required List<T> tracks,
  required String Function(T) idOf,
  required bool Function(T) isGroupOf,
  required String Function(T) parentGroupIdOf,
  bool Function(String groupId)? isCollapsed,
}) {
  final result = <T>[];
  final emitted = <String>{};

  for (final track in tracks) {
    if (parentGroupIdOf(track).isNotEmpty) continue;
    result.add(track);
    emitted.add(idOf(track));
    if (!isGroupOf(track)) continue;
    final groupId = idOf(track);
    final collapsed = isCollapsed?.call(groupId) ?? false;
    for (final child in tracks) {
      if (parentGroupIdOf(child) != groupId) continue;
      if (!collapsed) result.add(child);
      emitted.add(idOf(child));
    }
  }

  for (final track in tracks) {
    final id = idOf(track);
    if (emitted.contains(id)) continue;
    final parent = parentGroupIdOf(track);
    if (parent.isNotEmpty && (isCollapsed?.call(parent) ?? false)) continue;
    result.add(track);
  }
  return result;
}
