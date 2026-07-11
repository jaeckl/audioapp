part of 'engine_bridge.dart';

extension EngineBridgeDuplicateclipOperation on EngineBridge {
  Future<ProjectSnapshot> duplicateClip(String clipId) async {
    return _invokeForSnapshot('duplicateClip', {'clipId': clipId});
  }
}
