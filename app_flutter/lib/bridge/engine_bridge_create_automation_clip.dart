part of 'engine_bridge.dart';

extension EngineBridgeCreateautomationclipOperation on EngineBridge {
  Future<ProjectSnapshot> createAutomationClip({
    required String trackId,
    double startBeat = 0,
    double lengthBeats = 4,
  }) async {
    return _invokeForSnapshot('createAutomationClip', {
      'trackId': trackId,
      'startBeat': startBeat,
      'lengthBeats': lengthBeats,
    });
  }
}
