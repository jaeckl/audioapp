part of 'library_fly_in_panel.dart';

extension LibraryFlyInPanelStateCloseOperation on LibraryFlyInPanelState {
Future<void> close() async {
    _stopPreviewAnimation();
    await _controller.reverse();
    if (mounted) widget.onClose();
  }
}
