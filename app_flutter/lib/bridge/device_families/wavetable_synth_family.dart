part of '../device_snapshot.dart';

class WavetableSynthDeviceSnapshot extends DeviceSnapshot {
  const WavetableSynthDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.wavetableId,
    required this.wtPosition,
    required this.wtOctave,
    required this.wtSemitone,
    required this.wtFine,
    required this.wtUnison,
    required this.wtDetune,
    required this.filterMode,
    required this.filterCutoff,
    required this.filterResonance,
    required this.filterEnvAmount,
    required this.filterAttack,
    required this.filterDecay,
    required this.filterSustain,
    required this.filterRelease,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
  }) : super(type: 'wavetable_synth');

  final String wavetableId;
  final double wtPosition;
  final double wtOctave;
  final double wtSemitone;
  final double wtFine;
  final double wtUnison;
  final double wtDetune;
  final int filterMode;
  final double filterCutoff;
  final double filterResonance;
  final double filterEnvAmount;
  final double filterAttack;
  final double filterDecay;
  final double filterSustain;
  final double filterRelease;
  final double attack;
  final double decay;
  final double sustain;
  final double release;

  factory WavetableSynthDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return WavetableSynthDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      wavetableId: (params['wavetableId'] as String?) ?? 'sine_64',
      wtPosition: (params['wtPosition'] as num?)?.toDouble() ?? 0.0,
      wtOctave: (params['wtOctave'] as num?)?.toDouble() ?? 0.5,
      wtSemitone: (params['wtSemitone'] as num?)?.toDouble() ?? 0.5,
      wtFine: (params['wtFine'] as num?)?.toDouble() ?? 0.5,
      wtUnison: (params['wtUnison'] as num?)?.toDouble() ?? 0.0,
      wtDetune: (params['wtDetune'] as num?)?.toDouble() ?? 0.0,
      filterMode: (params['filterMode'] as num?)?.toInt() ?? 0,
      filterCutoff: (params['filterCutoff'] as num?)?.toDouble() ?? 1.0,
      filterResonance: (params['filterResonance'] as num?)?.toDouble() ?? 0.0,
      filterEnvAmount: (params['filterEnvAmount'] as num?)?.toDouble() ?? 0.0,
      filterAttack: (params['filterAttack'] as num?)?.toDouble() ?? 0.1,
      filterDecay: (params['filterDecay'] as num?)?.toDouble() ?? 0.3,
      filterSustain: (params['filterSustain'] as num?)?.toDouble() ?? 0.5,
      filterRelease: (params['filterRelease'] as num?)?.toDouble() ?? 0.5,
      attack: (params['attack'] as num?)?.toDouble() ?? 0.01,
      decay: (params['decay'] as num?)?.toDouble() ?? 0.2,
      sustain: (params['sustain'] as num?)?.toDouble() ?? 0.8,
      release: (params['release'] as num?)?.toDouble() ?? 0.3,
    );
  }

  @override
  WavetableSynthDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    String? wavetableId,
    double? wtPosition,
    double? wtOctave,
    double? wtSemitone,
    double? wtFine,
    double? wtUnison,
    double? wtDetune,
    int? filterMode,
    double? filterCutoff,
    double? filterResonance,
    double? filterEnvAmount,
    double? filterAttack,
    double? filterDecay,
    double? filterSustain,
    double? filterRelease,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
  }) {
    return WavetableSynthDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      wavetableId: wavetableId ?? this.wavetableId,
      wtPosition: wtPosition ?? this.wtPosition,
      wtOctave: wtOctave ?? this.wtOctave,
      wtSemitone: wtSemitone ?? this.wtSemitone,
      wtFine: wtFine ?? this.wtFine,
      wtUnison: wtUnison ?? this.wtUnison,
      wtDetune: wtDetune ?? this.wtDetune,
      filterMode: filterMode ?? this.filterMode,
      filterCutoff: filterCutoff ?? this.filterCutoff,
      filterResonance: filterResonance ?? this.filterResonance,
      filterEnvAmount: filterEnvAmount ?? this.filterEnvAmount,
      filterAttack: filterAttack ?? this.filterAttack,
      filterDecay: filterDecay ?? this.filterDecay,
      filterSustain: filterSustain ?? this.filterSustain,
      filterRelease: filterRelease ?? this.filterRelease,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
    );
  }

  @override
  WavetableSynthDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'attack' => copyWith(attack: value),
      'decay' => copyWith(decay: value),
      'sustain' => copyWith(sustain: value),
      'release' => copyWith(release: value),
      'filterCutoff' => copyWith(filterCutoff: value),
      'filterResonance' => copyWith(filterResonance: value),
      'filterMode' => copyWith(filterMode: value.round().clamp(0, 3)),
      'filterEnvAmount' => copyWith(filterEnvAmount: value),
      'filterAttack' => copyWith(filterAttack: value),
      'filterDecay' => copyWith(filterDecay: value),
      'filterSustain' => copyWith(filterSustain: value),
      'filterRelease' => copyWith(filterRelease: value),
      'wtPosition' => copyWith(wtPosition: value.clamp(0.0, 1.0)),
      'wtOctave' => copyWith(wtOctave: value.clamp(0.0, 1.0)),
      'wtSemitone' => copyWith(wtSemitone: value.clamp(0.0, 1.0)),
      'wtFine' => copyWith(wtFine: value.clamp(0.0, 1.0)),
      'wtUnison' => copyWith(wtUnison: value.clamp(0.0, 1.0)),
      'wtDetune' => copyWith(wtDetune: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
