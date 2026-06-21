import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'library_catalog.dart';
import 'library_category.dart';
import 'library_category_menu.dart';
import 'library_content_pane.dart';
import 'library_header.dart';
import 'library_manifest.dart';
import 'library_preset_preview_bar.dart';
import 'library_theme.dart';

/// Slide-in content library: half width in landscape, full width in portrait.
class LibraryFlyInPanel extends StatefulWidget {
  const LibraryFlyInPanel({
    super.key,
    required this.snapshot,
    required this.onClose,
    required this.onPreviewAudio,
    required this.onInsertAudio,
    required this.onImportAudio,
    this.initialCategory = LibraryCategory.audioClips,
    this.onMidiClipTap,
    this.onMidiPreviewTap,
    this.onAutomationTap,
    this.onAutomationPreviewTap,
    this.onPresetTap,
  });

  final ProjectSnapshot snapshot;
  final VoidCallback onClose;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final VoidCallback onImportAudio;
  final LibraryCategory initialCategory;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryMidiItem item)? onMidiPreviewTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryAutomationItem item)? onAutomationPreviewTap;
  final void Function(LibraryPresetItem item)? onPresetTap;

  @override
  State<LibraryFlyInPanel> createState() => LibraryFlyInPanelState();
}

class LibraryFlyInPanelState extends State<LibraryFlyInPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late LibraryCategory _category;
  LibraryManifest? _manifest;
  String? _selectedItemId;
  bool _presetPreviewLoopEnabled = true;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _loadManifest();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadManifest() async {
    try {
      final manifest = await LibraryManifest.load();
      if (mounted) {
        setState(() => _manifest = manifest);
      }
    } catch (_) {
      // manifest unavailable — non-critical
    }
  }

  Future<void> close() async {
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  void openCategory(LibraryCategory category) {
    setState(() {
      _category = category;
      _selectedItemId = null;
      _presetPreviewLoopEnabled = true;
    });
  }

  void _onItemSelected(String? itemId) {
    setState(() {
      _selectedItemId = itemId;
    });
  }

  void _onInsert() {
    if (_selectedItemId == null) return;
    final items = LibraryCatalog.itemsFor(
      _category,
      widget.snapshot,
      manifest: _manifest,
    );
    LibraryItem item;
    try {
      item = items.firstWhere((i) => i.id == _selectedItemId);
    } catch (_) {
      return;
    }
    switch (item) {
      case final LibraryAudioItem audio when !audio.isProjectClip:
        widget.onInsertAudio(audio.sample);
      case final LibraryMidiItem midi:
        widget.onMidiClipTap?.call(midi);
      case final LibraryAutomationItem automation:
        widget.onAutomationTap?.call(automation);
      case final LibraryPresetItem preset:
        widget.onPresetTap?.call(preset);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final panelWidth = landscape ? size.width * 0.5 : size.width;
    final accent = LibraryTheme.accentFor(_category);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: close,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: landscape ? Colors.black.withValues(alpha: 0.18) : Colors.black54,
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: panelWidth,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: LibraryTheme.panelBackground,
              elevation: 12,
              child: SafeArea(
                right: false,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: LibraryTheme.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LibraryHeader(
                        onClose: close,
                        selectedItemId: _selectedItemId,
                        onInsert: _selectedItemId != null ? _onInsert : null,
                        accent: accent,
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LibraryCategoryMenu(
                              selected: _category,
                              onSelected: (category) => setState(() {
                                _category = category;
                                _selectedItemId = null;
                                _presetPreviewLoopEnabled = true;
                              }),
                            ),
                            Expanded(
                              child: LibraryContentPane(
                                category: _category,
                                snapshot: widget.snapshot,
                                onPreviewAudio: widget.onPreviewAudio,
                                onInsertAudio: widget.onInsertAudio,
                                onImportAudio: widget.onImportAudio,
                                onItemSelected: _onItemSelected,
                                onMidiClipTap: widget.onMidiClipTap,
                                onMidiPreviewTap: widget.onMidiPreviewTap,
                                onAutomationTap: widget.onAutomationTap,
                                onAutomationPreviewTap: widget.onAutomationPreviewTap,
                                onPresetTap: widget.onPresetTap,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_category == LibraryCategory.devicePresets &&
                          _selectedItemId != null)
                        PresetPreviewBar(
                          snapshot: widget.snapshot,
                          selectedTrackId: widget.snapshot.selectedTrackId,
                          loopEnabled: _presetPreviewLoopEnabled,
                          onLoopToggled: (enabled) =>
                              setState(() => _presetPreviewLoopEnabled = enabled),
                          onScrub: (beat) {
                            // Bridge call for preset preview at this beat
                            // will be wired later (WP-BRIDGE)
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
