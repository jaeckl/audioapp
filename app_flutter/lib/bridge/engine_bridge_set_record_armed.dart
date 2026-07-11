part of 'engine_bridge.dart';

extension EngineBridgeSetrecordarmedOperation on EngineBridge {
Future<ProjectSnapshot> setRecordArmed(bool armed) async {
    return _invokeForSnapshot('setRecordArmed', {'armed': armed});
  }
}
