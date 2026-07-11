part of 'engine_bridge.dart';

extension EngineBridgeMovetrackOperation on EngineBridge {
  Future<ProjectSnapshot> moveTrack({
    required String trackId,
    String parentGroupId = '',
    String beforeTrackId = '',
  }) async {
    return _invokeForSnapshot('moveTrack', {
      'trackId': trackId,
      'parentGroupId': parentGroupId,
      'beforeTrackId': beforeTrackId,
    });
  }
}
