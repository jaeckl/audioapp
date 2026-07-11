part of 'engine_bridge.dart';

extension EngineBridgeGetdevicepresetOperation on EngineBridge {
  Future<String> getDevicePreset(String deviceId) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getDevicePreset',
      {'deviceId': deviceId},
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'preset_export_failed',
        message: 'Failed to export device preset',
      );
    }
    final data = result['snapshot'] as Map<dynamic, dynamic>?;
    final json = data?['presetJson'] as String?;
    if (json == null || json.isEmpty) {
      throw PlatformException(code: 'empty_device_preset');
    }
    return json;
  }
}
