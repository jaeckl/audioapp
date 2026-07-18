part of 'engine_bridge.dart';

extension EngineBridgeCreatelfoOperation on EngineBridge {
  Future<ProjectSnapshot> createLfo({
    int modulatorType = 0,
    String? deviceId,
  }) async {
    return _invokeForSnapshot('createLfo', {
      'modulatorType': modulatorType,
      if (deviceId != null) 'deviceId': deviceId,
    });
  }
}
