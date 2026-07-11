part of 'library_tag_filter_bar.dart';

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
