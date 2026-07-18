part of 'library_content_pane.dart';

class _LibraryContentPaneState extends State<LibraryContentPane> {
  LibraryManifest? _manifest;
  List<CurveLibraryResource> _curves = const [];
  final Set<String> _selectedTags = {};
  String? _selectedItemId;
  String? _selectedDeviceType; // null = show all

  @override
  void initState() {
    super.initState();
    _loadManifest();
    _loadCurves();
    _loadUserPresets();
  }

  Future<void> _loadUserPresets() async {
    await UserDevicePresetStore.load();
    if (mounted) setState(() {});
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
      if (widget.category == LibraryCategory.curves) _loadCurves();
    }
  }

  Future<void> _loadCurves() async {
    final curves = await CurveLibraryStore.load();
    if (mounted) setState(() => _curves = curves);
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
    if (widget.category == LibraryCategory.curves) {
      return LibraryCatalog.curveItems(_curves);
    }
    final all = LibraryCatalog.itemsFor(
      widget.category,
      widget.snapshot,
      manifest: _manifest,
    );
    if (widget.category == LibraryCategory.devicePresets) {
      var filtered = all;
      final typeFilter = widget.presetDeviceType ?? _selectedDeviceType;
      if (typeFilter != null) {
        filtered = filtered
            .where((item) =>
                item is LibraryPresetItem && item.deviceType == typeFilter)
            .toList();
      }
      if (widget.percussionOnly) {
        const percussionTypes = {
          'simple_sampler',
          'kick_generator',
          'snare_generator',
          'clap_generator',
          'hihat_generator',
          'ride_generator',
          'tom_generator',
          'rimshot_generator',
          'crash_generator',
        };
        filtered = filtered
            .where((item) =>
                item is LibraryPresetItem &&
                percussionTypes.contains(item.deviceType))
            .toList();
      }
      if (_selectedTags.isNotEmpty) {
        filtered = filtered
            .where(
                (item) => libraryItemMatchesTagFilter(item.tags, _selectedTags))
            .toList();
      }
      return filtered;
    }
    if (widget.category == LibraryCategory.midiClips) {
      if (_selectedTags.isNotEmpty) {
        return all
            .where(
                (item) => libraryItemMatchesTagFilter(item.tags, _selectedTags))
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
                  icon: const Icon(Icons.upload_file_outlined,
                      color: Colors.white70),
                ),
            ],
          ),
        ),
        if (widget.category == LibraryCategory.midiClips &&
            allMidiItems.isNotEmpty)
          LibraryTagFilterBar(
            itemTagLists: allMidiItems.map((m) => m.tags),
            selectedTags: _selectedTags,
            onTagToggled: _toggleTag,
            onClear: _onClearTags,
            accent: accent,
          ),
        if (widget.category == LibraryCategory.devicePresets &&
            allPresetItems.isNotEmpty &&
            widget.presetDeviceType == null)
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
          onLongPress: item is LibraryPresetItem && item.isUser
              ? () => widget.onUserPresetLongPress?.call(item)
              : null,
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
      case LibraryCurveItem():
        break;
      default:
        break;
    }
  }

  static String _headerTitle(LibraryCategory category) => switch (category) {
        LibraryCategory.audioClips => 'Audio clips',
        LibraryCategory.midiClips => 'MIDI clips',
        LibraryCategory.automationClips => 'Automation clips',
        LibraryCategory.curves => 'Curves',
        LibraryCategory.devicePresets => 'Device presets',
        LibraryCategory.wavetables => 'Wavetables',
      };
}
