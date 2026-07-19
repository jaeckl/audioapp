part of 'library_device_browser_pane.dart';

class _ResultsPage extends StatelessWidget {
  const _ResultsPage({
    required this.accent,
    required this.items,
    required this.selectedItemId,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.onSelect,
  });

  final Color accent;
  final List<LibraryDeviceBrowseItem> items;
  final String? selectedItemId;
  final List<String> availableTags;
  final Set<String> selectedTags;
  final ValueChanged<Set<String>> onTagsChanged;
  final ValueChanged<LibraryDeviceBrowseItem> onSelect;

  Future<void> _openTags(BuildContext context) async {
    final draft = Set<String>.from(selectedTags);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: LibraryTheme.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('TAGS', style: WelcomeTheme.sectionLabel),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            draft.clear();
                            setModal(() {});
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (availableTags.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No tags in this family yet',
                          style: TextStyle(color: LibraryTheme.labelMuted),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in availableTags)
                            FilterChip(
                              label: Text(tag),
                              selected: draft.contains(tag),
                              onSelected: (on) {
                                setModal(() {
                                  if (on) {
                                    draft.add(tag);
                                  } else {
                                    draft.remove(tag);
                                  }
                                });
                              },
                              selectedColor: accent.withValues(alpha: 0.25),
                              checkmarkColor: accent,
                              labelStyle: TextStyle(
                                color: draft.contains(tag)
                                    ? WelcomeTheme.textPrimary
                                    : LibraryTheme.labelMuted,
                              ),
                              side: BorderSide(
                                color: draft.contains(tag)
                                    ? accent.withValues(alpha: 0.6)
                                    : LibraryTheme.border,
                              ),
                              backgroundColor: LibraryTheme.cardBackground,
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () {
                        onTagsChanged(Set<String>.from(draft));
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (availableTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openTags(context),
                  icon: Icon(Icons.label_outline, size: 16, color: accent),
                  label: Text(
                    selectedTags.isEmpty
                        ? 'Tags'
                        : 'Tags (${selectedTags.length})',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WelcomeTheme.textPrimary,
                    side: BorderSide(color: accent.withValues(alpha: 0.45)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (selectedTags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedTags.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: LibraryTheme.labelMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'No devices or presets match',
                    style: TextStyle(color: LibraryTheme.labelMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _DeviceBrowseTile(
                      item: item,
                      accent: accent,
                      selected: item.id == selectedItemId,
                      onTap: () => onSelect(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DeviceBrowseTile extends StatelessWidget {
  const _DeviceBrowseTile({
    required this.item,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final LibraryDeviceBrowseItem item;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPreset = item is LibraryDevicePresetBrowseItem;
    final def = deviceDefinitionRepository.find(item.typeId);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LibraryTheme.cardBackground,
        borderRadius: BorderRadius.circular(LibraryTheme.panelRadius),
        border: Border.all(
          color: selected ? accent.withValues(alpha: 0.7) : LibraryTheme.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: selected ? LibraryTheme.selectedFill(accent) : Colors.transparent,
        borderRadius: BorderRadius.circular(LibraryTheme.panelRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LibraryTheme.panelRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: LibraryTheme.softFill(accent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(
                    def?.picker.icon ??
                        (isPreset ? Icons.tune : Icons.devices_other),
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LibraryTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LibraryTheme.labelMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  isPreset ? 'PRESET' : 'DEVICE',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
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
