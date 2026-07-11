part of 'engine_bridge.dart';

extension EngineBridgeRemovemodulationOperation on EngineBridge {
Future<ProjectSnapshot> removeModulation({
    required int lfoId,
    required String paramId,
    String? deviceId,
  }) async {
    final args = <String, dynamic>{
      'lfoId': lfoId,
      'paramId': paramId,
    };
    if (deviceId != null) {
      args['deviceId'] = deviceId;
    }
    return _invokeForSnapshot('removeModulation', args);
  }
}
