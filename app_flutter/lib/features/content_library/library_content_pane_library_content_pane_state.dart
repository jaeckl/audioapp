part of 'library_content_pane.dart';

enum _ResourceBrowseStep { primary, secondary, results }

enum _PrimaryFacet { none, role, source, deviceType }

class _LibraryContentPaneState extends State<LibraryContentPane> {
  LibraryManifest? _manifest;
  List<CurveLibraryResource> _curves = const [];
  final Set<String> _selectedTags = {};
  String? _selectedItemId;
  String? _selectedDeviceType;
  String? _primaryTag;
  String? _secondaryTag;
  late _ResourceBrowseStep _step;

  @override
  void initState() {
    super.initState();
    _step = _ResourceBrowseStep.results;
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
    if (widget.category != oldWidget.category ||
        widget.presetDeviceType != oldWidget.presetDeviceType ||
        widget.percussionOnly != oldWidget.percussionOnly) {
      _resetBrowse();
      if (widget.category == LibraryCategory.curves) _loadCurves();
    }
  }

  Future<void> _loadCurves() async {
    final curves = await CurveLibraryStore.load();
    if (mounted) setState(() => _curves = curves);
  }

  Future<void> _loadManifest() async {
    if (widget.presetManifest != null) {
      setState(() {
        _manifest = widget.presetManifest;
        _resetBrowse();
      });
      return;
    }
    try {
      final manifest = await LibraryManifest.load();
      if (mounted) {
        setState(() {
          _manifest = manifest;
          _resetBrowse();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _manifest = null;
          _resetBrowse();
        });
      }
    }
  }

  _PrimaryFacet get _primaryFacet {
    if (widget.category == LibraryCategory.devicePresets &&
        widget.presetDeviceType == null) {
      return _PrimaryFacet.deviceType;
    }
    return switch (widget.category) {
      LibraryCategory.audioClips || LibraryCategory.curves =>
        _PrimaryFacet.source,
      LibraryCategory.midiClips ||
      LibraryCategory.wavetables ||
      LibraryCategory.devicePresets =>
        _PrimaryFacet.role,
      LibraryCategory.automationClips => _PrimaryFacet.none,
    };
  }

  bool get _useSecondaryCharacter {
    if (_primaryFacet != _PrimaryFacet.role) return false;
    return libraryTagsForGroup(
      LibraryTagGroup.character,
      _allItems().map((i) => i.tags),
    ).isNotEmpty;
  }

  void _resetBrowse() {
    _selectedTags.clear();
    _selectedItemId = null;
    _selectedDeviceType = widget.presetDeviceType;
    _primaryTag = null;
    _secondaryTag = null;
    if (widget.presetDeviceType != null) {
      _step = _ResourceBrowseStep.results;
    } else if (_primaryFacet == _PrimaryFacet.none) {
      _step = _ResourceBrowseStep.results;
    } else {
      _step = _ResourceBrowseStep.primary;
    }
  }

  List<LibraryItem> _allItems() {
    if (widget.category == LibraryCategory.curves) {
      return LibraryCatalog.curveItems(_curves);
    }
    return LibraryCatalog.itemsFor(
      widget.category,
      widget.snapshot,
      manifest: _manifest,
    );
  }

  List<LibraryItem> _itemsMatching({
    String? primaryTag,
    String? secondaryTag,
    String? deviceType,
    Set<String> extraTags = const {},
  }) {
    var items = _allItems();
    if (widget.category == LibraryCategory.devicePresets) {
      final typeFilter = widget.presetDeviceType ?? deviceType;
      if (typeFilter != null) {
        items = items
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
        items = items
            .where((item) =>
                item is LibraryPresetItem &&
                percussionTypes.contains(item.deviceType))
            .toList();
      }
    }
    final pathTags = <String>{
      if (primaryTag != null) primaryTag,
      if (secondaryTag != null) secondaryTag,
      ...extraTags,
    };
    if (pathTags.isNotEmpty) {
      items = items
          .where((item) => libraryItemMatchesTagFilter(item.tags, pathTags))
          .toList();
    }
    return items;
  }

  List<LibraryItem> _visibleItems() => _itemsMatching(
        primaryTag: _primaryTag,
        secondaryTag: _secondaryTag,
        deviceType: _selectedDeviceType,
        extraTags: _selectedTags,
      );

  void _goPrimary() => setState(() {
        _step = _ResourceBrowseStep.primary;
        _primaryTag = null;
        _secondaryTag = null;
        _selectedDeviceType = widget.presetDeviceType;
        _selectedTags.clear();
        _selectedItemId = null;
        widget.onItemSelected?.call(null);
      });

  void _goSecondary({String? primaryTag, String? deviceType}) => setState(() {
        _step = _ResourceBrowseStep.secondary;
        _primaryTag = primaryTag;
        _selectedDeviceType = deviceType ?? widget.presetDeviceType;
        _secondaryTag = null;
        _selectedTags.clear();
        _selectedItemId = null;
        widget.onItemSelected?.call(null);
      });

  void _goResults({
    String? primaryTag,
    String? secondaryTag,
    String? deviceType,
  }) =>
      setState(() {
        _step = _ResourceBrowseStep.results;
        _primaryTag = primaryTag;
        _secondaryTag = secondaryTag;
        _selectedDeviceType = deviceType ?? widget.presetDeviceType;
        _selectedItemId = null;
        widget.onItemSelected?.call(null);
      });

  @override
  Widget build(BuildContext context) {
    final accent = LibraryTheme.accentFor(widget.category);
    final loading = (widget.category == LibraryCategory.devicePresets ||
            widget.category == LibraryCategory.midiClips) &&
        _manifest == null &&
        widget.presetManifest == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResourcePathBar(
          category: widget.category,
          step: _step,
          primaryFacet: _primaryFacet,
          primaryTag: _primaryTag,
          secondaryTag: _secondaryTag,
          deviceType: _selectedDeviceType,
          useSecondary: _useSecondaryCharacter,
          accent: accent,
          onImportAudio: widget.category == LibraryCategory.audioClips
              ? widget.onImportAudio
              : null,
          onCategoryTap: widget.presetDeviceType != null ? null : _goPrimary,
          onPrimaryTap: _step == _ResourceBrowseStep.results ||
                  _step == _ResourceBrowseStep.secondary
              ? _goPrimary
              : null,
          onSecondaryTap: _step == _ResourceBrowseStep.results &&
                  _useSecondaryCharacter
              ? () => _goSecondary(
                    primaryTag: _primaryTag,
                    deviceType: _selectedDeviceType,
                  )
              : null,
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : switch (_step) {
                  _ResourceBrowseStep.primary => _buildPrimaryPage(accent),
                  _ResourceBrowseStep.secondary => _buildSecondaryPage(accent),
                  _ResourceBrowseStep.results => _buildResults(accent),
                },
        ),
      ],
    );
  }
}
