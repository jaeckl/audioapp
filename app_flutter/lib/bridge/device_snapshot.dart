import 'device_families/device_snapshot_helpers.dart';

part 'device_families/bass_synth_family.dart';
part 'device_families/drum_generator_family.dart';
part 'device_families/dynamics_family.dart';
part 'device_families/effect_family.dart';
part 'device_families/frequency_fx_family.dart';
part 'device_families/resonator_bank_family.dart';
part 'device_families/oscillator_family.dart';
part 'device_families/phase_mod_synth_family.dart';
part 'device_families/sampler_family.dart';
part 'device_families/subtractive_synth_family.dart';
part 'device_families/wavetable_synth_family.dart';
part 'device_families/track_gain_family.dart';

sealed class DeviceSnapshot {
  const DeviceSnapshot({
    required this.id,
    required this.type,
    required this.gain,
    required this.pan,
    required this.bypassed,
    required this.meterGainReductionDb,
    required this.meterInputLevel,
  });

  final String id;
  final String type;
  final double gain;
  final double pan;
  final bool bypassed;
  final double meterGainReductionDb;
  final double meterInputLevel;

  DeviceSnapshot withParameter(String parameterId, double value);

  DeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
  });

  factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String? ?? '';
    return switch (type) {
      'track_gain' => TrackGainDeviceSnapshot.fromMap(map),
      'simple_oscillator' => OscillatorDeviceSnapshot.fromMap(map),
      'simple_sampler' => SamplerDeviceSnapshot.fromMap(map),
      'subtractive_synth' => SubtractiveSynthDeviceSnapshot.fromMap(map),
      'phase_mod_synth' => PhaseModSynthDeviceSnapshot.fromMap(map),
      'wavetable_synth' => WavetableSynthDeviceSnapshot.fromMap(map),
      'bass_synth' => BassSynthDeviceSnapshot.fromMap(map),
      'kick_generator' => KickGeneratorDeviceSnapshot.fromMap(map),
      'snare_generator' => SnareGeneratorDeviceSnapshot.fromMap(map),
      'clap_generator' => ClapGeneratorDeviceSnapshot.fromMap(map),
      'cymbal_generator' => CymbalGeneratorDeviceSnapshot.fromMap(map),
      'crash_generator' => CrashGeneratorDeviceSnapshot.fromMap(map),
      'gate' => GateDeviceSnapshot.fromMap(map),
      'compressor' => CompressorDeviceSnapshot.fromMap(map),
      'expander' => ExpanderDeviceSnapshot.fromMap(map),
      'limiter' => LimiterDeviceSnapshot.fromMap(map),
      'delay' => DelayDeviceSnapshot.fromMap(map),
      'reverb' => ReverbDeviceSnapshot.fromMap(map),
      'chorus' => ChorusDeviceSnapshot.fromMap(map),
      'phaser' => PhaserDeviceSnapshot.fromMap(map),
      'bitcrusher' => BitcrusherDeviceSnapshot.fromMap(map),
      'distortion' => DistortionDeviceSnapshot.fromMap(map),
      'tremolo' => TremoloDeviceSnapshot.fromMap(map),
      'filter' => FilterDeviceSnapshot.fromMap(map),
      'four_band_eq' => FourBandEqDeviceSnapshot.fromMap(map),
      'frequency_shifter' => FrequencyShifterDeviceSnapshot.fromMap(map),
      'resonator_bank' => ResonatorBankDeviceSnapshot.fromMap(map),
      _ => throw ArgumentError('Unknown device type: $type'),
    };
  }
}




// --- Sealed Families ---
