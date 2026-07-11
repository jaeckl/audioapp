import 'package:audioapp/devices/definition/device_role.dart';
import 'package:audioapp/devices/generated_device_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated repository discovers all dynamics definitions', () {
    expect(
      generatedDeviceDefinitions.map((definition) => definition.typeId).toSet(),
      {'gate', 'compressor', 'expander', 'limiter'},
    );
    expect(
      generatedDeviceDefinitions
          .every((definition) => definition.role == DeviceRole.audioEffect),
      isTrue,
    );
  });
}
