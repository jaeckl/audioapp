import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/devices/definition/device_capability.dart';
import 'package:audioapp/devices/definition/device_definition.dart';
import 'package:audioapp/devices/definition/device_definition_repository.dart';
import 'package:audioapp/devices/definition/device_layout_metadata.dart';
import 'package:audioapp/devices/definition/device_picker_metadata.dart';
import 'package:audioapp/devices/definition/device_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository rejects duplicate self-owned type ids', () {
    expect(
      () => DeviceDefinitionRepository([_TestDefinition(), _TestDefinition()]),
      throwsStateError,
    );
  });

  test('repository delegates parsing to the owning definition', () {
    final repository = DeviceDefinitionRepository([_TestDefinition()]);
    final parsed =
        repository.parseSnapshot({'type': 'simple_oscillator', 'id': 'x'});
    expect(parsed.id, 'x');
  });
}

final class _TestDefinition implements DeviceDefinition<DeviceSnapshot> {
  @override
  Set<DeviceCapability> get capabilities => const {};
  @override
  DeviceLayoutMetadata get layout => const DeviceLayoutMetadata(
      designWidth: 1, inputPanelWidth: 0, outputPanelWidth: 0);
  @override
  DevicePickerMetadata get picker => const DevicePickerMetadata(
      name: 'Test',
      description: 'Test',
      icon: Icons.circle,
      color: Colors.white,
      category: 'test');
  @override
  DeviceRole get role => DeviceRole.instrument;
  @override
  String get typeId => 'simple_oscillator';
  @override
  DeviceSnapshot parseSnapshot(Map<dynamic, dynamic> map) =>
      DeviceSnapshot.fromMap(map);
}
