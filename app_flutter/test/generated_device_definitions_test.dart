import 'package:audioapp/devices/definition/device_role.dart';
import 'package:audioapp/devices/generated_device_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated repository discovers migrated device definitions', () {
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
        'simple_sampler',
        'simple_oscillator',
        'subtractive_synth',
        'bass_synth',
        'phase_mod_synth',
        'wavetable_synth',
        'granular_formant_synth',
        'kick_generator',
        'snare_generator',
        'clap_generator',
        'hihat_generator',
        'ride_generator',
        'tom_generator',
        'rimshot_generator',
        'crash_generator',
        'drum_machine',
        'audio_receiver',
        'midi_receiver',
        'midi_delay',
        'oscilloscope',
        'spectrum_analyzer',
        'loudness_meter',
        'stereo_imager',
        'device_chain',
        'lr_split',
        'ms_split',
        'track_gain',
      },
    );
    expect(
      generatedDeviceDefinitions
          .where((definition) =>
              definition.picker.category == 'Instruments' &&
              definition.typeId != 'device_chain')
          .every((definition) => definition.role == DeviceRole.instrument),
      isTrue,
    );
    expect(
      generatedDeviceDefinitions
          .singleWhere((definition) => definition.typeId == 'midi_delay')
          .role,
      DeviceRole.noteEffect,
    );
    expect(
      generatedDeviceDefinitions
          .singleWhere((definition) => definition.typeId == 'device_chain')
          .role,
      DeviceRole.utility,
    );
  });
}
