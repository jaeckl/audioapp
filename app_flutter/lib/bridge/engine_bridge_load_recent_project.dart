part of 'engine_bridge.dart';

extension EngineBridgeLoadrecentprojectOperation on EngineBridge {
  Future<ProjectSnapshot> loadRecentProject(String uri) =>
      _invokeForSnapshot('loadRecentProject', {'uri': uri});
}
