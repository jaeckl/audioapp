part of 'engine_bridge.dart';

extension EngineBridgeSelecttrackOperation on EngineBridge {
Future<ProjectSnapshot> selectTrack(String trackId) async {
    return _invokeForSnapshot('selectTrack', {'trackId': trackId});
  }
}
