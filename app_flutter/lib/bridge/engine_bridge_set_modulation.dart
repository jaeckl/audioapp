part of 'engine_bridge.dart';

extension EngineBridgeSetmodulationOperation on EngineBridge {
Future<void> setModulation(double mod) async {
    await _invokeOk('setModulation', {'mod': mod});
  }
}
