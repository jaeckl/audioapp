import 'package:flutter/material.dart';

import 'library_category.dart';
import 'library_device_family.dart';
import 'library_theme.dart';
import '../welcome/welcome_theme.dart';

part 'library_category_menu_category_button.dart';

/// Left rail — resource categories or device families.
class LibraryCategoryMenu extends StatelessWidget {
  const LibraryCategoryMenu({
    super.key,
    required this.onSelected,
    this.selected,
    this.categories = kLibraryResourceRail,
    this.deviceFamilies,
    this.selectedFamily,
    this.onFamilySelected,
  });

  final LibraryCategory? selected;
  final ValueChanged<LibraryCategory> onSelected;
  final List<LibraryCategory> categories;

  final List<LibraryDeviceFamily>? deviceFamilies;
  final LibraryDeviceFamily? selectedFamily;
  final ValueChanged<LibraryDeviceFamily>? onFamilySelected;

  @override
  Widget build(BuildContext context) {
    final deviceMode = deviceFamilies != null;
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
            if (deviceMode)
              for (final family in deviceFamilies!)
                _FamilyButton(
                  family: family,
                  selected: family == selectedFamily,
                  onTap: () => onFamilySelected?.call(family),
                )
            else
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

class _FamilyButton extends StatelessWidget {
  const _FamilyButton({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final LibraryDeviceFamily family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = family.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  family.icon,
                  size: 22,
                  color: selected ? accent : LibraryTheme.labelMuted,
                ),
                const SizedBox(height: 6),
                Text(
                  family.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: selected
                            ? WelcomeTheme.textPrimary
                            : LibraryTheme.labelMuted,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
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
