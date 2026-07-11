part of 'engine_bridge.dart';

extension EngineBridgeAssignautomationtargetOperation on EngineBridge {
  Future<ProjectSnapshot> assignAutomationTarget({
    required String clipId,
    required String deviceId,
    required String paramId,
  }) async {
    return _invokeForSnapshot('assignAutomationTarget', {
      'clipId': clipId,
      'deviceId': deviceId,
      'paramId': paramId,
    });
  }
}
