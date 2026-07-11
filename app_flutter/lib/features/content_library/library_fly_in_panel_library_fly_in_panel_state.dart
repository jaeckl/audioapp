part of 'library_fly_in_panel.dart';

class LibraryFlyInPanelState extends State<LibraryFlyInPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late LibraryCategory _category;
  LibraryManifest? _manifest;
  String? _selectedItemId;
  bool _presetPreviewLoopEnabled = true;
  double _presetScrubBeat = 0.0;

  /// Preview timing state. When [_previewActive] is true the timer tick
  /// advances [_presetScrubBeat] at the configured BPM so the playhead
  /// visually moves while the engine plays.
  bool _previewActive = false;
  bool _previewLoop = true;
  double _previewLengthBeats = 0.0;
  double _previewStartBeat = 0.0;
  int _previewBpm = 120;
  DateTime? _previewStartedAt;
  Timer? _previewTicker;

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
    UserDevicePresetStore.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _previewTicker?.cancel();
    super.dispose();
  }

  /// Starts (or restarts) the visual playhead timer so the bar's playhead
  /// line tracks the engine's preview playhead. The math mirrors the engine:
  /// beat = startBeat + elapsed_seconds * (bpm / 60).
  /// Wraps the parent's preset preview callback to:
  ///  - inject the current preview-bar scrub beat as the default startBeat
  ///  - inject the current auto-play/loop state as the default `loop`
  ///  - keep the panel's stored scrub beat in sync with what the user is playing
  ///  - animate the visual playhead while the engine is playing
  LibraryPresetItem? get _selectedUserPreset {
    if (_selectedItemId == null) return null;
    return LibraryCatalog.presetItems(_manifest).where((p) => p.id == _selectedItemId && p.isUser).firstOrNull;
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
                        title: widget.presetDeviceType == null ? 'Library' : 'Presets',
                        onSavePreset: _category == LibraryCategory.devicePresets && widget.onCaptureDevicePreset != null ? _savePreset : null,
                        updatePreset: _selectedUserPreset != null,
                        actionLabel: _category == LibraryCategory.devicePresets ? 'Load' : 'Insert',
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LibraryCategoryMenu(
                              selected: _category,
                              categories: widget.percussionOnly ? const [LibraryCategory.audioClips, LibraryCategory.devicePresets] : LibraryCategory.values,
                              onSelected: (category) => setState(() {
                                _category = category;
                                _selectedItemId = null;
                                _presetPreviewLoopEnabled = true;
                                _presetScrubBeat = 0;
                                _stopPreviewAnimation();
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
                                onPresetPreviewTap: _onPresetPreviewTap,
                                onWavetableTap: widget.onWavetableTap,
                                autoPlayOnSelect: _presetPreviewLoopEnabled,
                                percussionOnly: widget.percussionOnly,
                                presetDeviceType: widget.presetDeviceType,
                                onUserPresetLongPress: _manageUserPreset,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_category == LibraryCategory.devicePresets && _selectedItemId != null)
                        PresetPreviewBar(
                          snapshot: widget.snapshot,
                          selectedTrackId: widget.snapshot.selectedTrackId,
                          displayPlayhead: _presetPreviewLoopEnabled,
                          onClipTap: (clip) {
                            // Jump preview to the tapped clip's start beat
                            final items = LibraryCatalog.itemsFor(
                              _category,
                              widget.snapshot,
                              manifest: _manifest,
                            );
                            try {
                              final item = items.firstWhere((i) => i.id == _selectedItemId);
                              if (item is LibraryPresetItem) {
                                _onPresetPreviewTap(item, startBeat: clip.startBeat);
                              }
                            } catch (_) {}
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
