part of 'engine_bridge.dart';

extension EngineBridgeAddtrackOperation on EngineBridge {
  Future<ProjectSnapshot> addTrack({String? name}) async {
    return _invokeForSnapshot('addTrack', {'name': name ?? ''});
  }
}
