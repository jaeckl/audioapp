import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'library_catalog.dart';
import 'library_category.dart';
import 'library_category_menu.dart';
import 'library_content_pane.dart';
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
    this.onAutomationTap,
    this.onPresetTap,
  });

  final ProjectSnapshot snapshot;
  final VoidCallback onClose;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final ValueChanged<SampleLibraryEntrySnapshot> onInsertAudio;
  final VoidCallback onImportAudio;
  final LibraryCategory initialCategory;
  final void Function(LibraryMidiItem item)? onMidiClipTap;
  final void Function(LibraryAutomationItem item)? onAutomationTap;
  final void Function(LibraryPresetItem item)? onPresetTap;

  @override
  State<LibraryFlyInPanel> createState() => LibraryFlyInPanelState();
}

class LibraryFlyInPanelState extends State<LibraryFlyInPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late LibraryCategory _category;

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> close() async {
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  void openCategory(LibraryCategory category) {
    setState(() => _category = category);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final panelWidth = landscape ? size.width * 0.5 : size.width;

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
                      _LibraryPanelHeader(onClose: close),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LibraryCategoryMenu(
                              selected: _category,
                              onSelected: (category) => setState(() => _category = category),
                            ),
                            Expanded(
                              child: LibraryContentPane(
                                category: _category,
                                snapshot: widget.snapshot,
                                onPreviewAudio: widget.onPreviewAudio,
                                onInsertAudio: widget.onInsertAudio,
                                onImportAudio: widget.onImportAudio,
                                onMidiClipTap: widget.onMidiClipTap,
                                onAutomationTap: widget.onAutomationTap,
                                onPresetTap: widget.onPresetTap,
                              ),
                            ),
                          ],
                        ),
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

class _LibraryPanelHeader extends StatelessWidget {
  const _LibraryPanelHeader({required this.onClose});

  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
      child: Row(
        children: [
          Text(
            'Library',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Close library',
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
