part of 'engine_bridge.dart';

extension EngineBridgeCreateprojectOperation on EngineBridge {
  Future<ProjectSnapshot> createProject() async {
    return _invokeForSnapshot('createProject');
  }
}
