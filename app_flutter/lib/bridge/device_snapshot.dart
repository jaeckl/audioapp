import 'device_families/device_snapshot_helpers.dart';
import '../devices/device_repository.dart';

part 'device_families/bass_synth_family.dart';
part 'device_families/drum_generator_family.dart';
part 'device_families/dynamics_device_snapshot.dart';
part 'device_families/gate_device_snapshot.dart';
part 'device_families/compressor_device_snapshot.dart';
part 'device_families/expander_device_snapshot.dart';
part 'device_families/limiter_device_snapshot.dart';
part 'device_families/effect_family.dart';
part 'device_families/frequency_fx_family.dart';
part 'device_families/resonator_bank_family.dart';
part 'device_families/routing_family.dart';
part 'device_families/midi_delay_family.dart';
part 'device_families/oscillator_family.dart';
part 'device_families/phase_mod_synth_family.dart';
part 'device_families/sampler_family.dart';
part 'device_families/subtractive_synth_family.dart';
part 'device_families/wavetable_synth_family.dart';
part 'device_families/track_gain_family.dart';
part 'device_families/drum_machine_family.dart';
part 'device_families/analysis_family.dart';
part 'device_families/chain_family.dart';
part 'device_families/split_family.dart';
part 'device_families/multiband_split_family.dart';
part 'device_families/granular_family.dart';

part 'device_families/effect_family_delay_device_snapshot.dart';
part 'device_families/effect_family_reverb_device_snapshot.dart';
part 'device_families/effect_family_chorus_device_snapshot.dart';
part 'device_families/effect_family_phaser_device_snapshot.dart';
part 'device_families/effect_family_bitcrusher_device_snapshot.dart';
part 'device_families/effect_family_distortion_device_snapshot.dart';
part 'device_families/effect_family_tremolo_device_snapshot.dart';
part 'device_families/effect_family_stutter_device_snapshot.dart';
part 'device_families/drum_generator_family_kick_generator_device_snapshot.dart';
part 'device_families/drum_generator_family_snare_generator_device_snapshot.dart';
part 'device_families/drum_generator_family_clap_generator_device_snapshot.dart';
part 'device_families/drum_generator_family_dedicated_percussion_device_snapshot.dart';
part 'device_families/drum_generator_family_crash_generator_device_snapshot.dart';
part 'device_families/frequency_fx_family_filter_device_snapshot.dart';
part 'device_families/frequency_fx_family_four_band_eq_device_snapshot.dart';
part 'device_families/frequency_fx_family_frequency_shifter_device_snapshot.dart';
part 'device_families/drum_machine_family_drum_machine_device_snapshot.dart';

part 'device_snapshot_virtual_strip_host_snapshot.dart';
part 'device_snapshot_virtual_strip_device_access.dart';
part 'device_families/subtractive_synth_family_with_parameter_impl.dart';
part 'device_families/phase_mod_synth_family_with_parameter_impl.dart';
part 'device_families/phase_mod_synth_family_from_map.dart';
/// Helper to parse an optional device-list key from engine JSON.
List<DeviceSnapshot> parseDeviceList(Map<dynamic, dynamic> map, String key) {
  final raw = map[key];
  if (raw is! List) return const [];
  return raw
      .map(
        (value) => deviceDefinitionRepository.parseSnapshot(
          value as Map<dynamic, dynamic>,
        ),
      )
      .toList(growable: false);
}

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

  factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) =>
      deviceDefinitionRepository.parseSnapshot(map);
}

/// Implemented only by instrument snapshots that own virtual Note/Audio FX.
// --- Sealed Families ---
