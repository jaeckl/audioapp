import '../../bridge/project_snapshot.dart';
import 'device_capability.dart';
import 'device_definition.dart';
import 'device_role.dart';

abstract base class NoteEffectDefinition
    implements DeviceDefinition<DeviceSnapshot> {
  const NoteEffectDefinition();

  @override
  DeviceRole get role => DeviceRole.noteEffect;

  @override
  Set<DeviceCapability> get capabilities => const {
        DeviceCapability.emitsNotes,
        DeviceCapability.supportsPresets,
        DeviceCapability.supportsAutomation,
        DeviceCapability.supportsModulation,
      };
}
