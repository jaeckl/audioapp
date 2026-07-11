part of 'engine_bridge.dart';

extension EngineBridgeAddgrouptrackOperation on EngineBridge {
  Future<ProjectSnapshot> addGroupTrack({String? name}) async {
    return _invokeForSnapshot('addGroupTrack', {'name': name ?? ''});
  }
}
