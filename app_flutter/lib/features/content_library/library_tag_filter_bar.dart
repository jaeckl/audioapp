import 'package:flutter/material.dart';

import 'library_tags.dart';
import 'library_theme.dart';

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
    final characterTags = libraryTagsForGroup(LibraryTagGroup.character, itemTagLists);
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

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.tags,
    required this.selectedTags,
    required this.accent,
    required this.onTagToggled,
    this.onClear,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final Color accent;
  final ValueChanged<String> onTagToggled;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (onClear != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _TagChip(
                label: 'All',
                selected: selectedTags.isEmpty,
                accent: accent,
                onTap: onClear!,
              ),
            ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _TagChip(
                label: libraryTagLabel(tag),
                selected: selectedTags.contains(tag),
                accent: accent,
                onTap: () => onTagToggled(tag),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.22) : LibraryTheme.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : Colors.white24,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? accent : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
