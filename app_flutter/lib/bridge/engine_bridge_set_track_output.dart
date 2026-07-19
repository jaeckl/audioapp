part of 'engine_bridge.dart';

extension EngineBridgeSettrackoutputOperation on EngineBridge {
  Future<ProjectSnapshot> setTrackOutput({
    required String trackId,
    required String outputTarget,
  }) async {
    return _invokeForSnapshot('setTrackOutput', {
      'trackId': trackId,
      'outputTarget': outputTarget,
    });
  }
}
