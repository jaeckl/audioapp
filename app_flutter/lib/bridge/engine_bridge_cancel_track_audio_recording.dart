part of 'engine_bridge.dart';

extension EngineBridgeCanceltrackaudiorecordingOperation on EngineBridge {
  Future<void> cancelTrackAudioRecording() async {
    await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'cancelTrackAudioRecording',
    );
  }
}
