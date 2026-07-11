part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateOpencategoryOperation on LibraryFlyInPanelState {
void openCategory(LibraryCategory category) {
    setState(() {
      _category = category;
      _selectedItemId = null;
      _presetPreviewLoopEnabled = true;
      _presetScrubBeat = 0;
      _stopPreviewAnimation();
    });
  }
}
