part of 'engine_bridge.dart';

extension EngineBridgeSettrackmutedOperation on EngineBridge {
Future<ProjectSnapshot> setTrackMuted({
    required String trackId,
    required bool muted,
  }) async {
    return _invokeForSnapshot('setTrackMuted', {
      'trackId': trackId,
      'muted': muted,
    });
  }
}
