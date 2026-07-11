import 'package:flutter/material.dart';

import 'library_category.dart';
import 'library_theme.dart';

part 'library_category_menu_category_button.dart';

class LibraryCategoryMenu extends StatelessWidget {
  const LibraryCategoryMenu({
    super.key,
    required this.selected,
    required this.onSelected,
    this.categories = LibraryCategory.values,
  });

  final LibraryCategory selected;
  final ValueChanged<LibraryCategory> onSelected;
  final List<LibraryCategory> categories;

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
            for (final category in categories)
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
