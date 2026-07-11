part of 'engine_bridge.dart';

extension EngineBridgeCreatelfoOperation on EngineBridge {
  Future<ProjectSnapshot> createLfo({int modulatorType = 0}) async {
    return _invokeForSnapshot('createLfo', {'modulatorType': modulatorType});
  }
}
