part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateStoppreviewanimationOperation on LibraryFlyInPanelState {
void _stopPreviewAnimation() {
    _previewTicker?.cancel();
    _previewTicker = null;
    _previewActive = false;
  }
}
