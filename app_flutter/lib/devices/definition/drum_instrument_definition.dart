import '../../bridge/project_snapshot.dart';
import 'device_capability.dart';
import 'device_definition.dart';
import 'device_role.dart';

abstract base class DrumInstrumentDefinition
    implements DeviceDefinition<DeviceSnapshot> {
  const DrumInstrumentDefinition();

  @override
  DeviceRole get role => DeviceRole.instrument;

  @override
  Set<DeviceCapability> get capabilities => const {
        DeviceCapability.emitsAudio,
        DeviceCapability.supportsPresets,
        DeviceCapability.supportsAutomation,
        DeviceCapability.supportsModulation,
      };
}
