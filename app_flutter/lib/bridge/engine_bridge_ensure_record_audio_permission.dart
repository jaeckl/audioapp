part of 'engine_bridge.dart';

extension EngineBridgeEnsurerecordaudiopermissionOperation on EngineBridge {
  Future<void> ensureRecordAudioPermission() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'ensureRecordAudioPermission',
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'mic_permission_failed',
        message: 'Microphone permission was not granted',
      );
    }
  }
}
