part of 'engine_bridge.dart';

extension EngineBridgeBeginmidirecordingsessionOperation on EngineBridge {
  Future<void> beginMidiRecordingSession({
    required String trackId,
    required double startBeat,
    double quantizeStep = 0.25,
  }) async {
    await _invokeOk('beginMidiRecordingSession', {
      'trackId': trackId,
      'startBeat': startBeat,
      'quantizeStep': quantizeStep,
    });
  }
}
