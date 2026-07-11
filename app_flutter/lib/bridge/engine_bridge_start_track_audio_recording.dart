part of 'engine_bridge.dart';

extension EngineBridgeStarttrackaudiorecordingOperation on EngineBridge {
Future<void> startTrackAudioRecording({
    required String sampleId,
    required String clipId,
  }) async {
    await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'startTrackAudioRecording',
      {
        'sampleId': sampleId,
        'clipId': clipId,
      },
    );
  }
}
