part of 'engine_bridge.dart';

extension EngineBridgeCreatesampleclipOperation on EngineBridge {
  Future<ProjectSnapshot> createSampleClip({
    required String trackId,
    required String sampleId,
    double startBeat = 0,
    double lengthBeats = 0,
  }) async {
    return _invokeForSnapshot('createSampleClip', {
      'trackId': trackId,
      'sampleId': sampleId,
      'startBeat': startBeat,
      'lengthBeats': lengthBeats,
    });
  }
}
