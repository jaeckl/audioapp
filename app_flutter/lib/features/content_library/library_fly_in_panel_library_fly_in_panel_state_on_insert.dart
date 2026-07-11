part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateOninsertOperation on LibraryFlyInPanelState {
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
}
