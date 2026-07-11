import '../../bridge/project_snapshot.dart';
import 'device_capability.dart';
import 'device_definition.dart';
import 'device_role.dart';

abstract base class AudioEffectDefinition
    implements DeviceDefinition<DeviceSnapshot> {
  const AudioEffectDefinition();

  @override
  DeviceRole get role => DeviceRole.audioEffect;

  @override
  Set<DeviceCapability> get capabilities => const {
        DeviceCapability.acceptsAudioInput,
        DeviceCapability.emitsAudio,
        DeviceCapability.supportsPresets,
        DeviceCapability.supportsAutomation,
        DeviceCapability.supportsModulation,
      };
}
