part of 'engine_bridge.dart';

extension EngineBridgeStoptrackaudiorecordingOperation on EngineBridge {
Future<void> stopTrackAudioRecording() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'stopTrackAudioRecording',
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'recording_failed',
        message: 'Failed to stop audio recording',
      );
    }
  }
}
