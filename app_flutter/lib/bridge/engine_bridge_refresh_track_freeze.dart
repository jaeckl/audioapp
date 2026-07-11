part of 'engine_bridge.dart';

extension EngineBridgeRefreshtrackfreezeOperation on EngineBridge {
  Future<ProjectSnapshot> refreshTrackFreeze(String trackId) async {
    return _invokeForSnapshot('refreshTrackFreeze', {'trackId': trackId});
  }
}
