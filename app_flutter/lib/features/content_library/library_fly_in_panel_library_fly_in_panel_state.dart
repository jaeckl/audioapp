part of 'library_fly_in_panel.dart';

class LibraryFlyInPanelState extends State<LibraryFlyInPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late LibraryCategory _category;
  late LibraryDeviceFamily _deviceFamily;
  LibraryManifest? _manifest;
  String? _selectedItemId;
  bool _presetPreviewLoopEnabled = true;
  double _presetScrubBeat = 0.0;

  bool _previewActive = false;
  bool _previewLoop = true;
  double _previewLengthBeats = 0.0;
  double _previewStartBeat = 0.0;
  int _previewBpm = 120;
  DateTime? _previewStartedAt;
  Timer? _previewTicker;

  bool get _devicesMode => widget.browseMode == LibraryBrowseMode.devices;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory == LibraryCategory.devicePresets &&
            !_devicesMode
        ? LibraryCategory.audioClips
        : widget.initialCategory;
    if (_category == LibraryCategory.devicePresets && !_devicesMode) {
      _category = LibraryCategory.audioClips;
    }
    _deviceFamily = widget.lockedDeviceFamily ??
        (widget.presetDeviceType != null
            ? libraryDeviceFamilyForType(widget.presetDeviceType!)
            : widget.initialDeviceFamily);
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

  LibraryPresetItem? get _selectedUserPreset {
    if (_selectedItemId == null) return null;
    return LibraryCatalog.presetItems(_manifest)
        .where((p) => p.id == _selectedItemId && p.isUser)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;
    final panelWidth = landscape ? size.width * 0.5 : size.width;
    final accent = _devicesMode
        ? _deviceFamily.accent
        : LibraryTheme.accentFor(_category);
    final families = widget.lockedDeviceFamily != null
        ? <LibraryDeviceFamily>[widget.lockedDeviceFamily!]
        : LibraryDeviceFamily.values;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: close,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: landscape
                  ? Colors.black.withValues(alpha: 0.18)
                  : Colors.black54,
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
                    border: Border(
                      right: BorderSide(color: LibraryTheme.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LibraryHeader(
                        onClose: close,
                        selectedItemId: _selectedItemId,
                        onInsert: _selectedItemId != null ? _onInsert : null,
                        accent: accent,
                        title: _devicesMode
                            ? (widget.lockedDeviceFamily != null
                                ? 'Insert ${widget.lockedDeviceFamily!.title}'
                                : 'Devices')
                            : 'Library',
                        subtitle: _devicesMode
                            ? 'Devices and presets'
                            : 'Browse project resources',
                        onSavePreset: !_devicesMode &&
                                _category == LibraryCategory.devicePresets &&
                                widget.onCaptureDevicePreset != null
                            ? _savePreset
                            : (_devicesMode &&
                                    widget.onCaptureDevicePreset != null
                                ? _savePreset
                                : null),
                        updatePreset: _selectedUserPreset != null,
                        actionLabel: _devicesMode
                            ? (_selectedItemId?.startsWith('device:') == true
                                ? 'Add'
                                : 'Load')
                            : (_category == LibraryCategory.devicePresets
                                ? 'Load'
                                : 'Insert'),
                      ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LibraryCategoryMenu(
                              selected: _category,
                              categories: widget.percussionOnly
                                  ? const [
                                      LibraryCategory.audioClips,
                                    ]
                                  : kLibraryResourceRail,
                              onSelected: (category) => setState(() {
                                _category = category;
                                _selectedItemId = null;
                                _presetPreviewLoopEnabled = true;
                                _presetScrubBeat = 0;
                                _stopPreviewAnimation();
                              }),
                              deviceFamilies: _devicesMode ? families : null,
                              selectedFamily:
                                  _devicesMode ? _deviceFamily : null,
                              onFamilySelected: (family) => setState(() {
                                _deviceFamily = family;
                                _selectedItemId = null;
                                _stopPreviewAnimation();
                              }),
                            ),
                            Expanded(
                              child: _devicesMode
                                  ? LibraryDeviceBrowserPane(
                                      family: _deviceFamily,
                                      manifest: _manifest,
                                      selectedItemId: _selectedItemId,
                                      percussionOnly: widget.percussionOnly,
                                      lockedTypeId: widget.presetDeviceType,
                                      onItemSelected: (id) => setState(
                                          () => _selectedItemId = id),
                                      onSelectDeviceType: (typeId) {
                                        setState(() =>
                                            _selectedItemId = 'device:$typeId');
                                      },
                                      onSelectPreset: (item) {
                                        setState(
                                            () => _selectedItemId = item.id);
                                      },
                                    )
                                  : LibraryContentPane(
                                      category: _category,
                                      snapshot: widget.snapshot,
                                      onPreviewAudio: widget.onPreviewAudio,
                                      onInsertAudio: widget.onInsertAudio,
                                      onImportAudio: widget.onImportAudio,
                                      onItemSelected: _onItemSelected,
                                      onMidiClipTap: widget.onMidiClipTap,
                                      onMidiPreviewTap: widget.onMidiPreviewTap,
                                      onAutomationTap: widget.onAutomationTap,
                                      onAutomationPreviewTap:
                                          widget.onAutomationPreviewTap,
                                      onPresetTap: widget.onPresetTap,
                                      onPresetPreviewTap: _onPresetPreviewTap,
                                      onWavetableTap: widget.onWavetableTap,
                                      autoPlayOnSelect:
                                          _presetPreviewLoopEnabled,
                                      percussionOnly: widget.percussionOnly,
                                      presetDeviceType: widget.presetDeviceType,
                                      onUserPresetLongPress: _manageUserPreset,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      if ((_devicesMode ||
                              _category == LibraryCategory.devicePresets) &&
                          _selectedItemId != null &&
                          !_selectedItemId!.startsWith('device:'))
                        PresetPreviewBar(
                          snapshot: widget.snapshot,
                          selectedTrackId: widget.snapshot.selectedTrackId,
                          displayPlayhead: _presetPreviewLoopEnabled,
                          onClipTap: (clip) {
                            final items = LibraryCatalog.presetItems(_manifest);
                            try {
                              final item = items
                                  .firstWhere((i) => i.id == _selectedItemId);
                              _onPresetPreviewTap(item,
                                  startBeat: clip.startBeat);
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
