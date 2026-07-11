part of 'engine_bridge.dart';

extension EngineBridgeCancelmidirecordingsessionOperation on EngineBridge {
  Future<void> cancelMidiRecordingSession() async {
    await _invokeOk('cancelMidiRecordingSession');
  }
}
