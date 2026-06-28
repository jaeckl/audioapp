import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_preset_filter_list.dart';
import 'library_catalog.dart';
import 'library_category.dart';
import 'library_manifest.dart';
import 'library_preview_widget.dart';
import 'library_tag_filter_bar.dart';
import 'library_tags.dart';
import 'library_theme.dart';

class LibraryContentPane extends StatefulWidget {
  const LibraryContentPane({
    super.key,
    required this.category,
    required this.snapshot,
    required this.onPreviewAudio,
    required this.onInsertAudio,
    required this.onImportAudio,
    this.onItemSelected,
    this.onMidiClipTap,
    this.onMidiPreviewTap,
    this.onAutomationTap,
    this.onAutomationPreviewTap,
    this.onPresetTap,
    this.onPresetPreviewTap,
    this.onWavetableTap,
    this.autoPlayOnSelect = true,
    this.presetManifest,
  });

  final LibraryCategory category;
  final ProjectSnapshot snapshot;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final VoidCallback onImportAudio;
  final ValueChanged<String?>? onItemSelected;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryMidiItem item)? onMidiPreviewTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryAutomationItem item)? onAutomationPreviewTap;
  final void Function(LibraryPresetItem item)? onPresetTap;
  final void Function(LibraryPresetItem item, {double startBeat, bool loop})? onPresetPreviewTap;
  final void Function(LibraryWavetableItem item)? onWavetableTap;

  /// When true (default), selecting a preset auto-starts preview. When false,
  /// only the explicit play button on the tile starts preview.
  final bool autoPlayOnSelect;

  /// Optional manifest override (tests). When null, loads from assets.
  final LibraryManifest? presetManifest;

  @override
  State<LibraryContentPane> createState() => _LibraryContentPaneState();
}

class _LibraryContentPaneState extends State<LibraryContentPane> {
  LibraryManifest? _manifest;
  final Set<String> _selectedTags = {};
  String? _selectedItemId;
  String? _selectedDeviceType; // null = show all

  @override
  void initState() {
    super.initState();
    _loadManifest();
  }

  @override
  void didUpdateWidget(covariant LibraryContentPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.presetManifest != oldWidget.presetManifest) {
      _loadManifest();
    }
    if (widget.category != oldWidget.category) {
      _selectedTags.clear();
      _selectedItemId = null;
      _selectedDeviceType = null;
    }
  }

  Future<void> _loadManifest() async {
    if (widget.presetManifest != null) {
      setState(() => _manifest = widget.presetManifest);
      return;
    }
    try {
      final manifest = await LibraryManifest.load();
      if (mounted) {
        setState(() => _manifest = manifest);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _manifest = null);
      }
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
      _selectedItemId = null;
    });
  }

  void _onClearTags() {
    setState(() {
      _selectedTags.clear();
      _selectedItemId = null;
    });
  }

  List<LibraryItem> _visibleItems() {
    final all = LibraryCatalog.itemsFor(
      widget.category,
      widget.snapshot,
      manifest: _manifest,
    );
    if (widget.category == LibraryCategory.devicePresets) {
      var filtered = all;
      if (_selectedDeviceType != null) {
        filtered = filtered
            .where((item) =>
                item is LibraryPresetItem &&
                item.deviceType == _selectedDeviceType)
            .toList();
      }
      if (_selectedTags.isNotEmpty) {
        filtered = filtered
            .where((item) =>
                libraryItemMatchesTagFilter(item.tags, _selectedTags))
            .toList();
      }
      return filtered;
    }
    if (widget.category == LibraryCategory.midiClips) {
      if (_selectedTags.isNotEmpty) {
        return all
            .where((item) =>
                libraryItemMatchesTagFilter(item.tags, _selectedTags))
            .toList();
      }
      return all;
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems();
    final theme = Theme.of(context);
    final accent = LibraryTheme.accentFor(widget.category);
    final allPresetItems = widget.category == LibraryCategory.devicePresets
        ? LibraryCatalog.presetItems(_manifest)
        : const <LibraryPresetItem>[];
    final allMidiItems = widget.category == LibraryCategory.midiClips
        ? LibraryCatalog.factoryMidiItems(_manifest)
        : const <LibraryMidiItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headerTitle(widget.category),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.category.subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: LibraryTheme.labelMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.category == LibraryCategory.audioClips)
                IconButton(
                  tooltip: 'Import audio',
                  onPressed: widget.onImportAudio,
                  icon: const Icon(Icons.upload_file_outlined, color: Colors.white70),
                ),
            ],
          ),
        ),
        if (widget.category == LibraryCategory.midiClips && allMidiItems.isNotEmpty)
          LibraryTagFilterBar(
            itemTagLists: allMidiItems.map((m) => m.tags),
            selectedTags: _selectedTags,
            onTagToggled: _toggleTag,
            onClear: _onClearTags,
            accent: accent,
          ),
        if (widget.category == LibraryCategory.devicePresets && allPresetItems.isNotEmpty)
          DevicePresetFilterList(
            selectedType: _selectedDeviceType,
            onFilterChanged: (type) {
              setState(() {
                _selectedDeviceType = type;
                _selectedItemId = null;
              });
            },
          ),
        Expanded(
          child: _buildBody(items, accent),
        ),
      ],
    );
  }

  Widget _buildBody(List<LibraryItem> items, Color accent) {
    if (widget.category == LibraryCategory.devicePresets && _manifest == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (widget.category == LibraryCategory.midiClips && _manifest == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (items.isEmpty) {
      if ((widget.category == LibraryCategory.devicePresets ||
              widget.category == LibraryCategory.midiClips) &&
          (_selectedTags.isNotEmpty || _selectedDeviceType != null)) {
        return _FilteredEmptyState(
          onClear: () => setState(_selectedTags.clear),
          category: widget.category,
        );
      }
      return _EmptyCategoryState(category: widget.category);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = _selectedItemId == item.id;
        return _LibraryItemTile(
          item: item,
          accent: accent,
          isSelected: isSelected,
          onTap: () => _onItemTap(item),
          onPreviewAudio: widget.onPreviewAudio,
          onInsertAudio: widget.onInsertAudio,
          onMidiClipTap: widget.onMidiClipTap,
          onMidiPreviewTap: widget.onMidiPreviewTap,
          onAutomationTap: widget.onAutomationTap,
          onAutomationPreviewTap: widget.onAutomationPreviewTap,
           onPresetTap: widget.onPresetTap,
           onPresetPreviewTap: widget.onPresetPreviewTap,
           onWavetableTap: widget.onWavetableTap,
           autoPlayOnSelect: widget.autoPlayOnSelect,
        );
      },
    );
  }

  void _onItemTap(LibraryItem item) {
    // Always select the item
    setState(() {
      _selectedItemId = item.id;
    });
    widget.onItemSelected?.call(item.id);

    // Dispatch preview per item type, but only auto-play on selection when enabled.
    // Audio/MIDI/automation tiles are still auto-played (selection IS the action);
    // preset tiles gate the auto-play behind [autoPlayOnSelect] because the user
    // might want to insert (via the header) without auditioning.
    switch (item) {
      case final LibraryAudioItem audio when !audio.isProjectClip:
        widget.onPreviewAudio(audio.sample);
      case final LibraryMidiItem midi:
        widget.onMidiPreviewTap?.call(midi);
      case final LibraryAutomationItem automation:
        widget.onAutomationPreviewTap?.call(automation);
      case final LibraryPresetItem preset:
        if (widget.autoPlayOnSelect) {
          widget.onPresetPreviewTap?.call(preset);
        }
      case final LibraryWavetableItem wt:
        widget.onWavetableTap?.call(wt);
      default:
        break;
    }
  }

  static String _headerTitle(LibraryCategory category) => switch (category) {
        LibraryCategory.audioClips => 'Audio clips',
        LibraryCategory.midiClips => 'MIDI clips',
        LibraryCategory.automationClips => 'Automation clips',
        LibraryCategory.devicePresets => 'Device presets',
        LibraryCategory.wavetables => 'Wavetables',
      };
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onClear, required this.category});

  final VoidCallback onClear;
  final LibraryCategory category;

  @override
  Widget build(BuildContext context) {
    final label = category == LibraryCategory.midiClips
        ? 'No MIDI clips match these filters.'
        : 'No presets match these filters.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LibraryTheme.labelMuted,
                  ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onClear, child: const Text('Clear filters')),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({required this.category});

  final LibraryCategory category;

  @override
  Widget build(BuildContext context) {
    final message = switch (category) {
      LibraryCategory.audioClips => 'Import audio or add sample clips to the project.',
      LibraryCategory.midiClips => 'Factory loops and project clips appear here.',
      LibraryCategory.automationClips => 'Automation clips will appear here once recorded.',
      LibraryCategory.devicePresets => 'Starter presets will be listed here.',
      LibraryCategory.wavetables => 'Bundled wavetables will be listed here.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: LibraryTheme.labelMuted),
        ),
      ),
    );
  }
}

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
  });

  final LibraryItem item;
  final Color accent;
  final bool isSelected;
  final VoidCallback? onTap;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryMidiItem item)? onMidiPreviewTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryAutomationItem item)? onAutomationPreviewTap;
  final void Function(LibraryPresetItem item)? onPresetTap;
  final void Function(LibraryPresetItem item, {double startBeat, bool loop})? onPresetPreviewTap;
  final void Function(LibraryWavetableItem item)? onWavetableTap;
  final bool autoPlayOnSelect;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: isSelected ? accent.withValues(alpha: 0.08) : LibraryTheme.cardBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
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
          Icon(Icons.north_west, size: 18, color: accent.withValues(alpha: 0.8)),
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
      _ => const <Widget>[],
    };
  }
}

class _LeadingVisual extends StatelessWidget {
  const _LeadingVisual({
    required this.item,
    required this.accent,
  });

  final LibraryItem item;
  final Color accent;

  static const int _kPreviewPeakCount = 50;

  static List<double> _generateAutomationPeaks(
      List<AutomationPointSnapshot> points, double lengthBeats) {
    if (points.isEmpty || lengthBeats <= 0) return [];
    final peaks = List.filled(_kPreviewPeakCount, 0.0);
    for (final point in points) {
      final bin = ((point.beat / lengthBeats) * _kPreviewPeakCount)
          .round()
          .clamp(0, _kPreviewPeakCount - 1);
      peaks[bin] = (point.value + 1.0) / 2.0;
    }
    return peaks;
  }

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      LibraryAudioItem(:final sample) => LibraryPreviewWidget(
          width: 52,
          height: 36,
          peaks: sample.waveformPeaks,
          color: accent,
        ),
      LibraryMidiItem(:final clip) => LibraryPreviewWidget(
          width: 52,
          height: 36,
          notes: clip.notes,
          lengthBeats: clip.lengthBeats,
          color: accent,
        ),
      LibraryAutomationItem(:final clip) => clip != null
          ? LibraryPreviewWidget(
              width: 52,
              height: 36,
              peaks:
                  _generateAutomationPeaks(clip.points, clip.lengthBeats),
              color: accent,
            )
          : LibraryPreviewWidget(
              width: 52,
              height: 36,
              peaks: const [0.0, 0.3, 0.6, 0.8, 0.6, 0.3, 0.0],
              color: accent,
            ),
      _ => LibraryPreviewWidget(
          width: 52,
          height: 36,
          peaks: null,
          color: accent,
        ),
    };
  }
}
