part of 'engine_bridge.dart';

extension EngineBridgeCreatemidiclipOperation on EngineBridge {
  Future<ProjectSnapshot> createMidiClip({
    required String trackId,
    double startBeat = 0,
    double lengthBeats = ArrangementTimelineMetrics.defaultMidiClipLengthBeats,
  }) async {
    return _invokeForSnapshot('createMidiClip', {
      'trackId': trackId,
      'startBeat': startBeat,
      'lengthBeats': lengthBeats,
    });
  }
}
