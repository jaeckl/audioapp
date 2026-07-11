part of 'engine_bridge.dart';

extension EngineBridgeFlattenmidicompOperation on EngineBridge {
  Future<ProjectSnapshot> flattenMidiComp({required String clipId}) =>
      _invokeForSnapshot('flattenMidiComp', {'clipId': clipId});
}
