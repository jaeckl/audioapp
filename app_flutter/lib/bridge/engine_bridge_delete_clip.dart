part of 'engine_bridge.dart';

extension EngineBridgeDeleteclipOperation on EngineBridge {
  Future<ProjectSnapshot> deleteClip(String clipId) async {
    return _invokeForSnapshot('deleteClip', {'clipId': clipId});
  }
}
