import 'package:flutter/material.dart';

import 'library_category.dart';
import 'library_theme.dart';

class LibraryCategoryMenu extends StatelessWidget {
  const LibraryCategoryMenu({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final LibraryCategory selected;
  final ValueChanged<LibraryCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: LibraryTheme.menuBackground,
        border: Border(right: BorderSide(color: LibraryTheme.border)),
      ),
      child: SizedBox(
        width: LibraryTheme.menuWidth,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final category in LibraryCategory.values)
              _CategoryButton(
                category: category,
                selected: category == selected,
                onTap: () => onSelected(category),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final LibraryCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = LibraryTheme.accentFor(category);
    final icon = switch (category) {
      LibraryCategory.audioClips => Icons.graphic_eq,
      LibraryCategory.midiClips => Icons.piano,
      LibraryCategory.automationClips => Icons.show_chart,
      LibraryCategory.devicePresets => Icons.tune,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? accent : LibraryTheme.labelMuted,
                ),
                const SizedBox(height: 6),
                Text(
                  category.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected ? Colors.white : LibraryTheme.labelMuted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 10,
                        height: 1.1,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
