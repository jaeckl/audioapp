part of 'daw_shell.dart';

extension DawShellStateAssigndroppedsampletodeviceOperation on _DawShellState {
Future<void> _assignDroppedSampleToDevice(
    DeviceSnapshot device,
    SampleClipDragData sample,
  ) async {
    if (device is! SamplerDeviceSnapshot && device is! GranularDeviceSnapshot) {
      return;
    }
    await _setDeviceStringParameter(device.id, 'sampleId', sample.sampleId);
  }
}
