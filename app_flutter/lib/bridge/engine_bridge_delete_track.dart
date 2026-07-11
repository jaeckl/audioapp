part of 'engine_bridge.dart';

extension EngineBridgeDeletetrackOperation on EngineBridge {
  Future<ProjectSnapshot> deleteTrack(String trackId) async {
    return _invokeForSnapshot('deleteTrack', {'trackId': trackId});
  }
}
