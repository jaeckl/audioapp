part of 'device_snapshot.dart';

abstract interface class VirtualStripHostSnapshot {
  List<DeviceSnapshot> get audioFxDevices;
  List<DeviceSnapshot> get noteFxDevices;

  DeviceSnapshot copyWith({
    List<DeviceSnapshot>? audioFxDevices,
    List<DeviceSnapshot>? noteFxDevices,
  });
}
