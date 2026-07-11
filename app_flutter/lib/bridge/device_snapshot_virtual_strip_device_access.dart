part of 'device_snapshot.dart';

extension VirtualStripDeviceAccess on DeviceSnapshot {
  List<DeviceSnapshot> get audioFxDevices => this is VirtualStripHostSnapshot
      ? (this as VirtualStripHostSnapshot).audioFxDevices
      : const [];
  List<DeviceSnapshot> get noteFxDevices => this is VirtualStripHostSnapshot
      ? (this as VirtualStripHostSnapshot).noteFxDevices
      : const [];
}
