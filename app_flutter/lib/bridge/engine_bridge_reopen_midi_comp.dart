part of 'engine_bridge.dart';

extension EngineBridgeReopenmidicompOperation on EngineBridge {
Future<ProjectSnapshot> reopenMidiComp({required String clipId}) =>
      _invokeForSnapshot('reopenMidiComp', {'clipId': clipId});
}
