part of 'engine_bridge.dart';

extension EngineBridgeFreezetrackOperation on EngineBridge {
  Future<ProjectSnapshot> freezeTrack(String trackId) async {
    return _invokeForSnapshot('freezeTrack', {'trackId': trackId});
  }
}
