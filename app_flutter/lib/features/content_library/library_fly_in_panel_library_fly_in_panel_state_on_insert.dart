part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateOninsertOperation on LibraryFlyInPanelState {
  void _onInsert() {
    if (_selectedItemId == null) return;

    if (_selectedItemId!.startsWith('device:')) {
      final typeId = _selectedItemId!.substring('device:'.length);
      widget.onInsertDeviceType?.call(typeId);
      return;
    }

    if (_devicesMode) {
      final presets = LibraryCatalog.presetItems(_manifest);
      try {
        final preset = presets.firstWhere((p) => p.id == _selectedItemId);
        widget.onPresetTap?.call(preset);
      } catch (_) {}
      return;
    }

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
}
