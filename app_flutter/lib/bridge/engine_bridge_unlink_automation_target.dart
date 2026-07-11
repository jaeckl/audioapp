part of 'engine_bridge.dart';

extension EngineBridgeUnlinkautomationtargetOperation on EngineBridge {
Future<ProjectSnapshot> unlinkAutomationTarget(
      {required String clipId}) async {
    return _invokeForSnapshot('unlinkAutomationTarget', {'clipId': clipId});
  }
}
