part of 'engine_bridge.dart';

extension EngineBridgeAssignmodulationOperation on EngineBridge {
  Future<ProjectSnapshot> assignModulation({
    required int lfoId,
    required String deviceId,
    required String paramId,
    required double amount,
  }) async {
    return _invokeForSnapshot('assignModulation', {
      'lfoId': lfoId,
      'deviceId': deviceId,
      'paramId': paramId,
      'amount': amount,
    });
  }
}
