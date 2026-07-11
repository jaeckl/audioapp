import '../../bridge/project_snapshot.dart';
import 'device_capability.dart';
import 'device_layout_metadata.dart';
import 'device_picker_metadata.dart';
import 'device_role.dart';

abstract interface class DeviceDefinition<T extends DeviceSnapshot> {
  String get typeId;
  DeviceRole get role;
  Set<DeviceCapability> get capabilities;
  DevicePickerMetadata get picker;
  DeviceLayoutMetadata get layout;

  T parseSnapshot(Map<dynamic, dynamic> map);
}
