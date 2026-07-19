part of 'library_content_pane.dart';

extension _LibraryContentPaneStatePages on _LibraryContentPaneState {
  Widget _buildPrimaryPage(Color accent) {
    if (_primaryFacet == _PrimaryFacet.deviceType) {
      return _buildDeviceTypePage(accent);
    }
    final group = _primaryFacet == _PrimaryFacet.source
        ? LibraryTagGroup.source
        : LibraryTagGroup.role;
    final tags = libraryTagsForGroup(group, _allItems().map((i) => i.tags));
    if (tags.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _step == _ResourceBrowseStep.primary) {
          _goResults();
        }
      });
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final title = group == LibraryTagGroup.source ? 'All sources' : 'All roles';
    final rows = <(String?, String)>[
      (null, title),
      for (final tag in tags) (tag, libraryTagLabel(tag)),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final (tag, label) = rows[index];
        final count = _itemsMatching(primaryTag: tag).length;
        return _ResourceNavTile(
          title: label,
          subtitle:
              tag == null ? 'Skip this filter' : widget.category.subtitle,
          count: count,
          accent: accent,
          icon: _iconForTag(tag),
          onTap: () {
            if (_useSecondaryCharacter) {
              _goSecondary(primaryTag: tag);
            } else {
              _goResults(primaryTag: tag);
            }
          },
        );
      },
    );
  }

  Widget _buildDeviceTypePage(Color accent) {
    final types = <String>{};
    for (final item in _allItems()) {
      if (item is LibraryPresetItem) types.add(item.deviceType);
    }
    final filters = [
      for (final f in kDevicePresetFilters)
        if (types.contains(f.deviceType)) f,
      for (final type in types)
        if (!kDevicePresetFilters.any((f) => f.deviceType == type))
          DevicePresetFilter(
            deviceType: type,
            label: type,
            icon: Icons.tune,
          ),
    ];
    final rows = <(String?, String, IconData)>[
      (null, 'All types', Icons.apps),
      for (final f in filters) (f.deviceType, f.label, f.icon),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final (type, label, icon) = rows[index];
        final count = _itemsMatching(deviceType: type).length;
        return _ResourceNavTile(
          title: label,
          subtitle: type ?? 'Every device preset',
          count: count,
          accent: accent,
          icon: icon,
          onTap: () {
            if (_useSecondaryCharacter) {
              _goSecondary(deviceType: type);
            } else {
              _goResults(deviceType: type);
            }
          },
        );
      },
    );
  }

  Widget _buildSecondaryPage(Color accent) {
    final tags = libraryTagsForGroup(
      LibraryTagGroup.character,
      _itemsMatching(
        primaryTag: _primaryTag,
        deviceType: _selectedDeviceType,
      ).map((i) => i.tags),
    );
    final rows = <(String?, String)>[
      (null, 'All character'),
      for (final tag in tags) (tag, libraryTagLabel(tag)),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final (tag, label) = rows[index];
        final count = _itemsMatching(
          primaryTag: _primaryTag,
          secondaryTag: tag,
          deviceType: _selectedDeviceType,
        ).length;
        return _ResourceNavTile(
          title: label,
          subtitle: tag == null ? 'Skip character filter' : 'Character',
          count: count,
          accent: accent,
          icon: Icons.auto_awesome,
          onTap: () => _goResults(
            primaryTag: _primaryTag,
            secondaryTag: tag,
            deviceType: _selectedDeviceType,
          ),
        );
      },
    );
  }

  Widget _buildResults(Color accent) {
    final items = _visibleItems();
    final availableTags = libraryTagsPresentIn(items.map((i) => i.tags));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (availableTags.isNotEmpty || _selectedTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openTagsSheet(accent, availableTags),
                  icon: Icon(Icons.label_outline, size: 16, color: accent),
                  label: Text(
                    _selectedTags.isEmpty
                        ? 'Tags'
                        : 'Tags (${_selectedTags.length})',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: accent.withValues(alpha: 0.45)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (_selectedTags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedTags.map(libraryTagLabel).join(' · '),
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
        Expanded(child: _buildBody(items, accent)),
      ],
    );
  }

  Future<void> _openTagsSheet(Color accent, List<String> available) async {
    final draft = Set<String>.from(_selectedTags);
    final pool = {...available, ..._selectedTags}.toList()..sort();
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
                        Text('TAGS', style: Theme.of(ctx).textTheme.labelSmall),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in pool)
                          FilterChip(
                            label: Text(libraryTagLabel(tag)),
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
                            backgroundColor: LibraryTheme.cardBackground,
                            side: BorderSide(
                              color: draft.contains(tag)
                                  ? accent.withValues(alpha: 0.6)
                                  : LibraryTheme.border,
                            ),
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
                        setState(() {
                          _selectedTags
                            ..clear()
                            ..addAll(draft);
                          _selectedItemId = null;
                        });
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

  IconData _iconForTag(String? tag) {
    if (tag == null) return Icons.apps;
    return switch (tag) {
      'factory' => Icons.inventory_2_outlined,
      'imported' => Icons.download_outlined,
      'project' || 'user' => Icons.folder_outlined,
      'bass' => Icons.graphic_eq,
      'kick' || 'snare' => Icons.album,
      _ => Icons.label_outline,
    };
  }

  Widget _buildBody(List<LibraryItem> items, Color accent) {
    if (items.isEmpty) {
      if (_selectedTags.isNotEmpty ||
          _primaryTag != null ||
          _secondaryTag != null ||
          _selectedDeviceType != null) {
        return _FilteredEmptyState(
          onClear: _goPrimary,
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
    setState(() => _selectedItemId = item.id);
    widget.onItemSelected?.call(item.id);
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
}
