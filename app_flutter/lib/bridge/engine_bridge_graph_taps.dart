part of 'engine_bridge.dart';

typedef EffectiveParameterState = ({
  double automationBase,
  double effectiveValue,
});
typedef EffectiveParameterRequest = ({String deviceId, String parameterId});

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

  Future<EffectiveParameterState?> readEffectiveParameterState({
    required String deviceId,
    required String parameterId,
  }) async {
    final result = await invokeRaw('readEffectiveParameter', {
      'deviceId': deviceId,
      'parameterId': parameterId,
    });
    final effective = (result['value'] as num?)?.toDouble();
    if (effective == null) return null;
    return (
      automationBase:
          (result['automationBase'] as num?)?.toDouble() ?? effective,
      effectiveValue: effective,
    );
  }

  Future<List<EffectiveParameterState?>> readEffectiveParameterStates(
    List<EffectiveParameterRequest> requests,
  ) async {
    if (requests.isEmpty) return const [];
    final result = await invokeRaw('readEffectiveParameters', {
      'requests': [
        for (final request in requests)
          {
            'deviceId': request.deviceId,
            'parameterId': request.parameterId,
          },
      ],
    });
    final values = result['values'] as List<dynamic>? ?? const [];
    return List<EffectiveParameterState?>.generate(requests.length, (index) {
      if (index >= values.length || values[index] is! Map) return null;
      final value = values[index] as Map<dynamic, dynamic>;
      final effective = (value['value'] as num?)?.toDouble();
      if (effective == null) return null;
      return (
        automationBase:
            (value['automationBase'] as num?)?.toDouble() ?? effective,
        effectiveValue: effective,
      );
    });
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
