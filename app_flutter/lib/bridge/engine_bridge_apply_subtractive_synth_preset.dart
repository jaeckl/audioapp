part of 'engine_bridge.dart';

extension EngineBridgeApplysubtractivesynthpresetOperation on EngineBridge {
  Future<ProjectSnapshot> applySubtractiveSynthPreset({
    required String deviceId,
    required Map<String, double> params,
    List<Map<String, dynamic>> lfos = const [],
    List<Map<String, dynamic>> mods = const [],
  }) async {
    return _invokeForSnapshot('applySubtractiveSynthPreset', {
      'deviceId': deviceId,
      'params': params,
      'lfos': lfos,
      'mods': mods,
    });
  }
}
