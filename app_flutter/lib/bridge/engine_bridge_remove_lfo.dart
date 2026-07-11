part of 'engine_bridge.dart';

extension EngineBridgeRemovelfoOperation on EngineBridge {
Future<ProjectSnapshot> removeLfo(int lfoId) async {
    return _invokeForSnapshot('removeLfo', {'lfoId': lfoId});
  }
}
