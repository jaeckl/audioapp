part of 'engine_bridge.dart';

extension EngineBridgeGetprojectsnapshotOperation on EngineBridge {
  Future<ProjectSnapshot> getProjectSnapshot() async {
    return _invokeForSnapshot('getProjectSnapshot');
  }
}
