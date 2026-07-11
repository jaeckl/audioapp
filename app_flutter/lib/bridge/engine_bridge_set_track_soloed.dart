part of 'engine_bridge.dart';

extension EngineBridgeSettracksoloedOperation on EngineBridge {
Future<ProjectSnapshot> setTrackSoloed({
    required String trackId,
    required bool soloed,
  }) async {
    return _invokeForSnapshot('setTrackSoloed', {
      'trackId': trackId,
      'soloed': soloed,
    });
  }
}
