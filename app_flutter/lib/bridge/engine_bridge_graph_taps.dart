part of 'engine_bridge.dart';

extension EngineBridgeGraphTapsOperation on EngineBridge {
  Future<double?> readEffectiveParameter({
    required String deviceId,
    required String parameterId,
  }) async {
    final result = await invokeRaw('readEffectiveParameter', {
      'deviceId': deviceId,
      'parameterId': parameterId,
    });
    return (result['value'] as num?)?.toDouble();
  }

  Future<String> createGraphTap({
    required String deviceId,
    required String kind,
    int capacityFrames = 32768,
    String port = 'output',
  }) async {
    final arguments = <String, dynamic>{
      'deviceId': deviceId,
      'kind': kind,
      'capacityFrames': capacityFrames,
    };
    if (port != 'output') arguments['port'] = port;
    final result = await invokeRaw('createGraphTap', arguments);
    return result['tapId'] as String;
  }

  Future<void> removeGraphTap(String tapId) async {
    await invokeRaw('removeGraphTap', {'tapId': tapId});
  }

  Future<Map<dynamic, dynamic>> readGraphTap(
    String tapId, {
    int maxFrames = 512,
  }) {
    return invokeRaw('readGraphTap', {
      'tapId': tapId,
      'maxFrames': maxFrames,
    });
  }
}
