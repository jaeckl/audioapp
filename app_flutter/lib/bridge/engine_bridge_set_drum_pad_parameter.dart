part of 'engine_bridge.dart';

extension EngineBridgeSetdrumpadparameterOperation on EngineBridge {
Future<void> setDrumPadParameter({
    required String drumMachineId,
    required int note,
    required String parameterId,
    required double value,
  }) =>
      _invokeOk('setDrumPadParameter', {
        'drumMachineId': drumMachineId,
        'note': note,
        'parameterId': parameterId,
        'value': value,
      });
}
