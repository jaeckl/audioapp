import '../../bridge/project_snapshot.dart';
import 'device_capability.dart';
import 'device_definition.dart';
import 'device_role.dart';

abstract base class AnalysisDefinition
    implements DeviceDefinition<DeviceSnapshot> {
  const AnalysisDefinition();

  @override
  DeviceRole get role => DeviceRole.analysis;

  @override
  Set<DeviceCapability> get capabilities => const {
        DeviceCapability.acceptsAudioInput,
      };
}
