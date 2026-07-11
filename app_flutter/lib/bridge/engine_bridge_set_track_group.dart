part of 'engine_bridge.dart';

extension EngineBridgeSettrackgroupOperation on EngineBridge {
Future<ProjectSnapshot> setTrackGroup({
    required String trackId,
    String groupTrackId = '',
  }) async {
    return _invokeForSnapshot('setTrackGroup', {
      'trackId': trackId,
      'groupTrackId': groupTrackId,
    });
  }
}
