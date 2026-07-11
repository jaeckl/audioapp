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
part 'device_families/granular_family.dart';

/// Helper to parse an optional device-list key from engine JSON.
List<DeviceSnapshot> parseDeviceList(Map<dynamic, dynamic> map, String key) {
  final raw = map[key];
  if (raw is! List) return const [];
  return raw
      .map((v) => DeviceSnapshot.fromMap(v as Map<dynamic, dynamic>))
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
      'gate' ||
      'compressor' ||
      'expander' ||
      'limiter' =>
        deviceDefinitionRepository.parseSnapshot(map),
      'delay' ||
      'reverb' ||
      'chorus' ||
      'phaser' =>
        deviceDefinitionRepository.parseSnapshot(map),
      'bitcrusher' ||
      'distortion' ||
      'tremolo' ||
      'stutter_fx' =>
        deviceDefinitionRepository.parseSnapshot(map),
      'filter' ||
      'four_band_eq' ||
      'frequency_shifter' ||
      'resonator_bank' =>
        deviceDefinitionRepository.parseSnapshot(map),
      'audio_receiver' || 'midi_receiver' => RoutingDeviceSnapshot.fromMap(map),
      'midi_delay' => MidiDelayDeviceSnapshot.fromMap(map),
      'drum_machine' => DrumMachineDeviceSnapshot.fromMap(map),
      'device_chain' => ChainDeviceSnapshot.fromMap(map),
      'granular_formant_synth' => GranularDeviceSnapshot.fromMap(map),
      'oscilloscope' ||
      'spectrum_analyzer' ||
      'loudness_meter' ||
      'stereo_imager' =>
        AnalysisDeviceSnapshot.fromMap(map),
      _ => throw ArgumentError('Unknown device type: $type'),
    };
  }
}

/// Implemented only by instrument snapshots that own virtual Note/Audio FX.
abstract interface class VirtualStripHostSnapshot {
  List<DeviceSnapshot> get audioFxDevices;
  List<DeviceSnapshot> get noteFxDevices;

  DeviceSnapshot copyWith({
    List<DeviceSnapshot>? audioFxDevices,
    List<DeviceSnapshot>? noteFxDevices,
  });
}

extension VirtualStripDeviceAccess on DeviceSnapshot {
  List<DeviceSnapshot> get audioFxDevices => this is VirtualStripHostSnapshot
      ? (this as VirtualStripHostSnapshot).audioFxDevices
      : const [];
  List<DeviceSnapshot> get noteFxDevices => this is VirtualStripHostSnapshot
      ? (this as VirtualStripHostSnapshot).noteFxDevices
      : const [];
}

// --- Sealed Families ---
