import '../../bridge/project_snapshot.dart';
import 'device_definition.dart';

final class DeviceDefinitionRepository {
  DeviceDefinitionRepository(
      Iterable<DeviceDefinition<DeviceSnapshot>> definitions)
      : _definitions = _index(definitions);

  final Map<String, DeviceDefinition<DeviceSnapshot>> _definitions;

  static Map<String, DeviceDefinition<DeviceSnapshot>> _index(
      Iterable<DeviceDefinition<DeviceSnapshot>> definitions) {
    final result = <String, DeviceDefinition<DeviceSnapshot>>{};
    for (final definition in definitions) {
      if (result.containsKey(definition.typeId)) {
        throw StateError('Duplicate device definition: ${definition.typeId}');
      }
      result[definition.typeId] = definition;
    }
    return Map.unmodifiable(result);
  }

  DeviceDefinition<DeviceSnapshot> require(String typeId) {
    final definition = _definitions[typeId];
    if (definition == null) {
      throw ArgumentError.value(typeId, 'typeId', 'Unknown device type');
    }
    return definition;
  }

  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) {
    final typeId = map['type'] as String? ?? '';
    return require(typeId).parseSnapshot(map);
  }

  Iterable<DeviceDefinition<DeviceSnapshot>> get definitions =>
      _definitions.values;
}
