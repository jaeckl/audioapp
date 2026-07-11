part of 'automation_editor_screen.dart';

extension _AutomationEditorScreenStateStoppreviewplay
    on _AutomationEditorScreenState {
  Future<void> _stopPreviewPlay() async {
    if (!_previewTransport.isPlaying || _previewTransportCommandInFlight)
      return;
    _previewTransportCommandInFlight = true;
    try {
      await _previewTransport.stop();
    } finally {
      _previewTransportCommandInFlight = false;
    }
  }
}
