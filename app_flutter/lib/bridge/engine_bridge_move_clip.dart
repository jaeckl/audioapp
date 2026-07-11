part of 'engine_bridge.dart';

extension EngineBridgeMoveclipOperation on EngineBridge {
  Future<ProjectSnapshot> moveClip({
    required String clipId,
    required String trackId,
    required double startBeat,
  }) async {
    return _invokeForSnapshot('moveClip', {
      'clipId': clipId,
      'trackId': trackId,
      'startBeat': startBeat,
    });
  }
}
