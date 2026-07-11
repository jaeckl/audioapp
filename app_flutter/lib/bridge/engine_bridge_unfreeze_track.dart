part of 'engine_bridge.dart';

extension EngineBridgeUnfreezetrackOperation on EngineBridge {
Future<ProjectSnapshot> unfreezeTrack(String trackId) async {
    return _invokeForSnapshot('unfreezeTrack', {'trackId': trackId});
  }
}
