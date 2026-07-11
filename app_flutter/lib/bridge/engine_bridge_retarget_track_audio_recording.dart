part of 'engine_bridge.dart';

extension EngineBridgeRetargettrackaudiorecordingOperation on EngineBridge {
Future<void> retargetTrackAudioRecording({
    required String sampleId,
    required String clipId,
  }) async {
    await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'retargetTrackAudioRecording',
      {
        'sampleId': sampleId,
        'clipId': clipId,
      },
    );
  }
}
