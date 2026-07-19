import 'package:flutter/material.dart';

import '../../devices/device_repository.dart';
import '../welcome/welcome_theme.dart';
import 'library_device_catalog.dart';
import 'library_device_family.dart';
import 'library_manifest.dart';
import 'library_theme.dart';

part 'library_device_browser_pane_path_bar.dart';
part 'library_device_browser_pane_nav_tile.dart';
part 'library_device_browser_pane_results.dart';

enum _DeviceBrowseStep { kind, type, results }

/// Devices-mode explorer: Kind → Type → Results (tags refine on results).
class LibraryDeviceBrowserPane extends StatefulWidget {
  const LibraryDeviceBrowserPane({
    super.key,
    required this.family,
    required this.manifest,
    required this.onSelectDeviceType,
    required this.onSelectPreset,
    this.selectedItemId,
    this.onItemSelected,
    this.percussionOnly = false,
    this.lockedTypeId,
  });

  final LibraryDeviceFamily family;
  final LibraryManifest? manifest;
  final ValueChanged<String> onSelectDeviceType;
  final ValueChanged<LibraryDevicePresetBrowseItem> onSelectPreset;
  final String? selectedItemId;
  final ValueChanged<String?>? onItemSelected;
  final bool percussionOnly;
  final String? lockedTypeId;

  @override
  State<LibraryDeviceBrowserPane> createState() =>
      _LibraryDeviceBrowserPaneState();
}

class _LibraryDeviceBrowserPaneState extends State<LibraryDeviceBrowserPane> {
  late _DeviceBrowseStep _step;
  LibraryInstrumentKind? _kind;
  String? _typeId;
  final Set<String> _tags = {};

  bool get _showKindStep =>
      widget.family == LibraryDeviceFamily.instrument &&
      !widget.percussionOnly &&
      widget.lockedTypeId == null;

  @override
  void initState() {
    super.initState();
    _resetNav();
  }

  @override
  void didUpdateWidget(covariant LibraryDeviceBrowserPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.family != widget.family ||
        oldWidget.lockedTypeId != widget.lockedTypeId ||
        oldWidget.percussionOnly != widget.percussionOnly) {
      _resetNav();
    }
  }

  void _resetNav() {
    _tags.clear();
    if (widget.percussionOnly) {
      _kind = LibraryInstrumentKind.drum;
    } else {
      _kind = null;
    }
    _typeId = widget.lockedTypeId;
    if (widget.lockedTypeId != null) {
      _step = _DeviceBrowseStep.results;
      if (widget.family == LibraryDeviceFamily.instrument) {
        _kind = libraryInstrumentKindForType(widget.lockedTypeId!);
      }
    } else if (_showKindStep) {
      _step = _DeviceBrowseStep.kind;
    } else {
      _step = _DeviceBrowseStep.type;
    }
  }

  List<LibraryDeviceBrowseItem> _items({
    LibraryInstrumentKind? kind,
    String? typeId,
    Set<String> tags = const {},
  }) {
    return LibraryDeviceCatalog.itemsFor(
      family: widget.family,
      manifest: widget.manifest,
      kindFilter:
          widget.family == LibraryDeviceFamily.instrument ? kind : null,
      typeFilter: typeId,
      tags: tags,
      percussionOnly: widget.percussionOnly,
    );
  }

  void _goKind() => setState(() {
        _step = _DeviceBrowseStep.kind;
        _kind = null;
        _typeId = null;
        _tags.clear();
        widget.onItemSelected?.call(null);
      });

  void _goType({LibraryInstrumentKind? kind}) => setState(() {
        _step = _DeviceBrowseStep.type;
        _kind = kind;
        _typeId = null;
        _tags.clear();
        widget.onItemSelected?.call(null);
      });

  void _goResults({LibraryInstrumentKind? kind, String? typeId}) =>
      setState(() {
        _step = _DeviceBrowseStep.results;
        _kind = kind;
        _typeId = typeId;
        widget.onItemSelected?.call(null);
      });

  @override
  Widget build(BuildContext context) {
    final accent = widget.family.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PathBar(
          family: widget.family,
          showKind: _showKindStep || widget.percussionOnly,
          kind: _kind,
          typeId: widget.lockedTypeId ?? _typeId,
          step: _step,
          lockedType: widget.lockedTypeId != null,
          accent: accent,
          onFamilyTap: widget.lockedTypeId != null
              ? null
              : () {
                  if (_showKindStep) {
                    _goKind();
                  } else {
                    _goType();
                  }
                },
          onKindTap: widget.lockedTypeId != null || !_showKindStep
              ? null
              : _goKind,
          onTypeTap: widget.lockedTypeId != null
              ? null
              : () => _goType(kind: _kind),
        ),
        Expanded(child: _buildStep(accent)),
      ],
    );
  }

  Widget _buildStep(Color accent) {
    return switch (_step) {
      _DeviceBrowseStep.kind => _buildKindPage(accent),
      _DeviceBrowseStep.type => _buildTypePage(accent),
      _DeviceBrowseStep.results => _ResultsPage(
          accent: accent,
          items: _items(kind: _kind, typeId: _typeId, tags: _tags),
          selectedItemId: widget.selectedItemId,
          availableTags: LibraryDeviceCatalog.tagsInFamily(
            widget.family,
            manifest: widget.manifest,
          ),
          selectedTags: _tags,
          onTagsChanged: (tags) => setState(() {
            _tags
              ..clear()
              ..addAll(tags);
          }),
          onSelect: (item) {
            widget.onItemSelected?.call(item.id);
            switch (item) {
              case LibraryDeviceTypeItem():
                widget.onSelectDeviceType(item.typeId);
              case LibraryDevicePresetBrowseItem():
                widget.onSelectPreset(item);
            }
          },
        ),
    };
  }

  Widget _buildKindPage(Color accent) {
    final kinds = <(LibraryInstrumentKind?, String)>[
      (null, 'All instruments'),
      (LibraryInstrumentKind.synth, LibraryInstrumentKind.synth.title),
      (LibraryInstrumentKind.drum, LibraryInstrumentKind.drum.title),
      (LibraryInstrumentKind.sampler, LibraryInstrumentKind.sampler.title),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: kinds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final (kind, label) = kinds[index];
        final count = _items(kind: kind).length;
        return _NavTile(
          title: label,
          subtitle: kind == null
              ? 'Skip kind filter'
              : widget.family.subtitle,
          count: count,
          accent: accent,
          icon: switch (kind) {
            LibraryInstrumentKind.synth => Icons.piano,
            LibraryInstrumentKind.drum => Icons.album,
            LibraryInstrumentKind.sampler => Icons.graphic_eq,
            _ => Icons.apps,
          },
          onTap: () => _goType(kind: kind),
        );
      },
    );
  }

  Widget _buildTypePage(Color accent) {
    final typeIds = LibraryDeviceCatalog.deviceTypesInFamily(widget.family)
        .where((id) {
      if (_kind == null) return true;
      return libraryInstrumentKindForType(id) == _kind;
    }).toList();
    final rows = <(String?, String, String)>[
      (
        null,
        'All types',
        _kind == null ? 'Every device in family' : 'All ${_kind!.title} types',
      ),
      for (final id in typeIds)
        (
          id,
          deviceDefinitionRepository.find(id)?.picker.name ?? id,
          deviceDefinitionRepository.find(id)?.picker.description ?? id,
        ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final (typeId, title, subtitle) = rows[index];
        final count = _items(kind: _kind, typeId: typeId).length;
        final def =
            typeId == null ? null : deviceDefinitionRepository.find(typeId);
        return _NavTile(
          title: title,
          subtitle: subtitle,
          count: count,
          accent: accent,
          icon: def?.picker.icon ?? Icons.devices_other,
          onTap: () => _goResults(kind: _kind, typeId: typeId),
        );
      },
    );
  }
}
