part of 'engine_bridge.dart';

extension EngineBridgeSetpitchbendOperation on EngineBridge {
Future<void> setPitchBend(double bend) async {
    await _invokeOk('setPitchBend', {'bend': bend});
  }
}
