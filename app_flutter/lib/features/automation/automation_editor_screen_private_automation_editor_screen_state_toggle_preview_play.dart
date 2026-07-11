part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateTogglepreviewplay
    on _AutomationEditorScreenState {
  Future<void> _togglePreviewPlay() async {
    if (_previewTransport.isPlaying) {
      await _stopPreviewPlay();
    } else {
      await _startPreviewPlay();
    }
  }
}
