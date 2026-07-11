part of 'library_content_pane.dart';

class _LibraryItemTile extends StatelessWidget {
  const _LibraryItemTile({
    required this.item,
    required this.accent,
    this.isSelected = false,
    this.onTap,
    required this.onPreviewAudio,
    required this.onInsertAudio,
    this.onMidiClipTap,
    this.onMidiPreviewTap,
    this.onAutomationTap,
    this.onAutomationPreviewTap,
    this.onPresetTap,
    this.onPresetPreviewTap,
    this.onWavetableTap,
    this.autoPlayOnSelect = true,
    this.onLongPress,
  });

  final LibraryItem item;
  final Color accent;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryMidiItem item)? onMidiPreviewTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryAutomationItem item)? onAutomationPreviewTap;
  final void Function(LibraryPresetItem item)? onPresetTap;
  final void Function(LibraryPresetItem item, {double startBeat, bool loop})?
      onPresetPreviewTap;
  final void Function(LibraryWavetableItem item)? onWavetableTap;
  final bool autoPlayOnSelect;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: isSelected
          ? accent.withValues(alpha: 0.08)
          : LibraryTheme.cardBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _LeadingVisual(item: item, accent: accent),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ..._trailingActions(),
            ],
          ),
        ),
      ),
    );

    if (!isSelected) {
      return tile;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: tile,
    );
  }

  List<Widget> _trailingActions() {
    return switch (item) {
      final LibraryAudioItem audio when !audio.isProjectClip => [
          IconButton(
            tooltip: 'Preview',
            onPressed: () => onPreviewAudio(audio.sample),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white70),
          ),
        ],
      LibraryMidiItem(:final isFactory) when isFactory => [
          IconButton(
            tooltip: 'Preview',
            onPressed: () => onMidiPreviewTap?.call(item as LibraryMidiItem),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white70),
          ),
        ],
      LibraryMidiItem() => [
          Icon(Icons.north_west,
              size: 18, color: accent.withValues(alpha: 0.8)),
        ],
      LibraryAutomationItem() => [
          Icon(Icons.timeline, size: 18, color: accent.withValues(alpha: 0.8)),
        ],
      final LibraryPresetItem preset => [
          IconButton(
            tooltip: 'Preview',
            onPressed: () => onPresetPreviewTap?.call(preset),
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white70),
          ),
        ],
      LibraryWavetableItem() => [
          Icon(Icons.waves, size: 18, color: accent.withValues(alpha: 0.8)),
        ],
      LibraryCurveItem() => [
          Icon(Icons.gesture_rounded,
              size: 18, color: accent.withValues(alpha: 0.8)),
        ],
      _ => const <Widget>[],
    };
  }
}
