import 'package:audioapp/devices/definition/device_role.dart';
import 'package:audioapp/devices/generated_device_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated repository discovers migrated effect definitions', () {
    expect(
      generatedDeviceDefinitions.map((definition) => definition.typeId).toSet(),
      {
        'gate',
        'compressor',
        'expander',
        'limiter',
        'delay',
        'reverb',
        'chorus',
        'phaser',
        'bitcrusher',
        'distortion',
        'tremolo',
        'stutter_fx',
        'filter',
        'four_band_eq',
        'frequency_shifter',
        'resonator_bank',
      },
    );
    expect(
      generatedDeviceDefinitions
          .every((definition) => definition.role == DeviceRole.audioEffect),
      isTrue,
    );
  });
}
