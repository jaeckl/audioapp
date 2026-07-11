part of 'engine_bridge.dart';

extension EngineBridgeLoadexampleprojectOperation on EngineBridge {
  Future<ProjectSnapshot> loadExampleProject(String projectJson) =>
      _invokeForSnapshot('loadExampleProject', {'projectJson': projectJson});
}
