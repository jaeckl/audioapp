import '../../bridge/project_snapshot.dart';
import 'device_capability.dart';
import 'device_definition.dart';
import 'device_role.dart';

abstract base class UtilityDefinition
    implements DeviceDefinition<DeviceSnapshot> {
  const UtilityDefinition();

  @override
  DeviceRole get role => DeviceRole.utility;

  @override
  Set<DeviceCapability> get capabilities => const {
        DeviceCapability.emitsAudio,
        DeviceCapability.supportsAutomation,
      };
}
