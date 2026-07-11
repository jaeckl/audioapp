import 'package:flutter/material.dart';

import 'library_tags.dart';
import 'library_theme.dart';

part 'library_tag_filter_bar_chip_row.dart';
part 'library_tag_filter_bar_tag_chip.dart';

/// Horizontal chip rows for faceted library tag filtering.
class LibraryTagFilterBar extends StatelessWidget {
  const LibraryTagFilterBar({
    super.key,
    required this.itemTagLists,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onClear,
    this.accent = LibraryTheme.accentPreset,
  });

  final Iterable<List<String>> itemTagLists;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onClear;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final roleTags = libraryTagsForGroup(LibraryTagGroup.role, itemTagLists);
    final characterTags =
        libraryTagsForGroup(LibraryTagGroup.character, itemTagLists);
    if (roleTags.isEmpty && characterTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChipRow(
            tags: roleTags,
            selectedTags: selectedTags,
            accent: accent,
            onTagToggled: onTagToggled,
            onClear: selectedTags.isEmpty ? null : onClear,
          ),
          if (characterTags.isNotEmpty) ...[
            const SizedBox(height: 6),
            _ChipRow(
              tags: characterTags,
              selectedTags: selectedTags,
              accent: accent,
              onTagToggled: onTagToggled,
            ),
          ],
        ],
      ),
    );
  }
}
