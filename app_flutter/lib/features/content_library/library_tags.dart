/// Controlled vocabulary for library item tags (faceted filter).
enum LibraryTagGroup {
  role,
  character,
  source,
}

const Map<String, LibraryTagGroup> kLibraryTagToGroup = {
  // Role — musical job
  'bass': LibraryTagGroup.role,
  'lead': LibraryTagGroup.role,
  'pad': LibraryTagGroup.role,
  'pluck': LibraryTagGroup.role,
  'keys': LibraryTagGroup.role,
  'kick': LibraryTagGroup.role,
  'snare': LibraryTagGroup.role,
  'fx': LibraryTagGroup.role,
  'texture': LibraryTagGroup.role,
  'init': LibraryTagGroup.role,
  'chords': LibraryTagGroup.role,
  'melody': LibraryTagGroup.role,
  // Character — sonic feel / genre
  'warm': LibraryTagGroup.character,
  'bright': LibraryTagGroup.character,
  'dark': LibraryTagGroup.character,
  'lofi': LibraryTagGroup.character,
  'aggressive': LibraryTagGroup.character,
  'clean': LibraryTagGroup.character,
  'edm': LibraryTagGroup.character,
  'dnb': LibraryTagGroup.character,
  'progressive': LibraryTagGroup.character,
  'groovy': LibraryTagGroup.character,
  'wobble': LibraryTagGroup.character,
  // Source
  'factory': LibraryTagGroup.source,
  'imported': LibraryTagGroup.source,
  'project': LibraryTagGroup.source,
};

const Map<LibraryTagGroup, List<String>> kLibraryTagsByGroup = {
  LibraryTagGroup.role: [
    'bass',
    'lead',
    'pad',
    'pluck',
    'keys',
    'kick',
    'snare',
    'fx',
    'texture',
    'init',
    'chords',
    'melody',
  ],
  LibraryTagGroup.character: [
    'warm',
    'bright',
    'dark',
    'lofi',
    'aggressive',
    'clean',
    'edm',
    'dnb',
    'progressive',
    'groovy',
    'wobble',
  ],
  LibraryTagGroup.source: [
    'factory',
    'imported',
    'project',
  ],
};

String libraryTagLabel(String tag) {
  if (tag == 'lofi') return 'Lo-fi';
  if (tag == 'fx') return 'FX';
  if (tag == 'edm') return 'EDM';
  if (tag == 'dnb') return 'DnB';
  if (tag == 'progressive') return 'Progressive';
  return tag[0].toUpperCase() + tag.substring(1);
}

LibraryTagGroup? libraryTagGroup(String tag) => kLibraryTagToGroup[tag];

/// Tags that appear on at least one [items] entry, ordered by group vocabulary.
List<String> libraryTagsPresentIn(Iterable<List<String>> itemTagLists) {
  final present = <String>{};
  for (final tags in itemTagLists) {
    present.addAll(tags);
  }
  final ordered = <String>[];
  for (final group in LibraryTagGroup.values) {
    for (final tag in kLibraryTagsByGroup[group]!) {
      if (present.contains(tag)) {
        ordered.add(tag);
      }
    }
  }
  return ordered;
}

List<String> libraryTagsForGroup(
  LibraryTagGroup group,
  Iterable<List<String>> itemTagLists,
) {
  final allowed = kLibraryTagsByGroup[group]!.toSet();
  return libraryTagsPresentIn(itemTagLists).where(allowed.contains).toList();
}

/// AND across groups, OR within each group.
bool libraryItemMatchesTagFilter(
  List<String> itemTags,
  Set<String> selectedTags,
) {
  if (selectedTags.isEmpty) {
    return true;
  }

  final selectedByGroup = <LibraryTagGroup, Set<String>>{};
  for (final tag in selectedTags) {
    final group = libraryTagGroup(tag);
    if (group == null) {
      continue;
    }
    selectedByGroup.putIfAbsent(group, () => {}).add(tag);
  }

  for (final entry in selectedByGroup.entries) {
    final groupTags = entry.value;
    final itemInGroup = itemTags.any(groupTags.contains);
    if (!itemInGroup) {
      return false;
    }
  }
  return true;
}
