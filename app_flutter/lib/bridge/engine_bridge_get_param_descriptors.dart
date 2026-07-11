part of 'engine_bridge.dart';

extension EngineBridgeGetparamdescriptorsOperation on EngineBridge {
  Future<List<DeviceParamDescriptor>> getParamDescriptors(
      String deviceType) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getParamDescriptors',
        {'deviceType': deviceType},
      );
      if (result == null || result['ok'] != true) return [];
      final params = result['params'] as List<dynamic>? ?? [];
      return params
          .map((p) => DeviceParamDescriptor.fromMap(p as Map<String, dynamic>))
          .toList();
    } on PlatformException {
      return [];
    }
  }
}
