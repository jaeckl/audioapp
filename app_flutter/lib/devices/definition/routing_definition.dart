import '../../bridge/project_snapshot.dart';
import 'device_capability.dart';
import 'device_definition.dart';
import 'device_role.dart';

abstract base class RoutingDefinition
    implements DeviceDefinition<DeviceSnapshot> {
  const RoutingDefinition();

  @override
  DeviceRole get role => DeviceRole.routing;

  @override
  Set<DeviceCapability> get capabilities => const {
        DeviceCapability.emitsAudio,
        DeviceCapability.supportsAutomation,
      };
}
