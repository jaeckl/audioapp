part of 'engine_bridge.dart';

extension EngineBridgeSetautomationpointsOperation on EngineBridge {
Future<ProjectSnapshot> setAutomationPoints({
    required String clipId,
    required List<AutomationPointSnapshot> points,
  }) async {
    return _invokeForSnapshot('setAutomationPoints', {
      'clipId': clipId,
      'points': points.map((p) => p.toMap()).toList(),
    });
  }
}
