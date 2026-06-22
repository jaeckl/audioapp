part of '../device_snapshot.dart';

/// Bass synth device snapshot.
class BassSynthDeviceSnapshot extends DeviceSnapshot {
  const BassSynthDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.bassOscShape,
    required this.bassSubMix,
    required this.bassSubOctave,
    required this.bassNoise,
    required this.bassFilterResonance,
    required this.bassDrive,
    required this.bassSquash,
    required this.bassOctave,
    required this.bassVelocitySense,
    required this.filterCutoff,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.filterEnvAmount,
    required this.filterDecay,
    required this.glideMs,
  }) : super(type: 'bass_synth');

  final double bassOscShape;
  final double bassSubMix;
  final int bassSubOctave;
  final double bassNoise;
  final double bassFilterResonance;
  final double bassDrive;
  final double bassSquash;
  final int bassOctave;
  final double bassVelocitySense;
  final double filterCutoff;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double filterEnvAmount;
  final double filterDecay;
  final double glideMs;

  factory BassSynthDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return BassSynthDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      bassOscShape: (params['bassOscShape'] as num?)?.toDouble() ?? 0.3,
      bassSubMix: (params['bassSubMix'] as num?)?.toDouble() ?? 0.5,
      bassSubOctave: (params['bassSubOctave'] as num?)?.toInt() ?? 0,
      bassNoise: (params['bassNoise'] as num?)?.toDouble() ?? 0.0,
      bassFilterResonance: (params['bassFilterResonance'] as num?)?.toDouble() ?? 0.25,
      bassDrive: (params['bassDrive'] as num?)?.toDouble() ?? 0.0,
      bassSquash: (params['bassSquash'] as num?)?.toDouble() ?? 0.0,
      bassOctave: (params['bassOctave'] as num?)?.toInt() ?? 2,
      bassVelocitySense: (params['bassVelocitySense'] as num?)?.toDouble() ?? 1.0,
      filterCutoff: (params['filterCutoff'] as num?)?.toDouble() ?? 1.0,
      attack: (params['attack'] as num?)?.toDouble() ?? 0.01,
      decay: (params['decay'] as num?)?.toDouble() ?? 0.3,
      sustain: (params['sustain'] as num?)?.toDouble() ?? 0.7,
      release: (params['release'] as num?)?.toDouble() ?? 0.4,
      filterEnvAmount: (params['filterEnvAmount'] as num?)?.toDouble() ?? 0.6,
      filterDecay: (params['filterDecay'] as num?)?.toDouble() ?? 0.4,
      glideMs: (params['glideMs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  BassSynthDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? bassOscShape,
    double? bassSubMix,
    int? bassSubOctave,
    double? bassNoise,
    double? bassFilterResonance,
    double? bassDrive,
    double? bassSquash,
    int? bassOctave,
    double? bassVelocitySense,
    double? filterCutoff,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    double? filterEnvAmount,
    double? filterDecay,
    double? glideMs,
  }) {
    return BassSynthDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      bassOscShape: bassOscShape ?? this.bassOscShape,
      bassSubMix: bassSubMix ?? this.bassSubMix,
      bassSubOctave: bassSubOctave ?? this.bassSubOctave,
      bassNoise: bassNoise ?? this.bassNoise,
      bassFilterResonance: bassFilterResonance ?? this.bassFilterResonance,
      bassDrive: bassDrive ?? this.bassDrive,
      bassSquash: bassSquash ?? this.bassSquash,
      bassOctave: bassOctave ?? this.bassOctave,
      bassVelocitySense: bassVelocitySense ?? this.bassVelocitySense,
      filterCutoff: filterCutoff ?? this.filterCutoff,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      filterEnvAmount: filterEnvAmount ?? this.filterEnvAmount,
      filterDecay: filterDecay ?? this.filterDecay,
      glideMs: glideMs ?? this.glideMs,
    );
  }

  @override
  BassSynthDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'bassOscShape' => copyWith(bassOscShape: value.clamp(0.0, 1.0)),
      'bassSubMix' => copyWith(bassSubMix: value.clamp(0.0, 1.0)),
      'bassSubOctave' => copyWith(bassSubOctave: value.round().clamp(0, 2)),
      'bassNoise' => copyWith(bassNoise: value.clamp(0.0, 1.0)),
      'bassFilterResonance' => copyWith(bassFilterResonance: value.clamp(0.0, 1.0)),
      'bassDrive' => copyWith(bassDrive: value.clamp(0.0, 1.0)),
      'bassSquash' => copyWith(bassSquash: value.clamp(0.0, 1.0)),
      'bassOctave' => copyWith(bassOctave: value.round().clamp(0, 4)),
      'bassVelocitySense' => copyWith(bassVelocitySense: value.clamp(0.0, 1.0)),
      'filterCutoff' => copyWith(filterCutoff: value),
      'attack' => copyWith(attack: value),
      'decay' => copyWith(decay: value),
      'sustain' => copyWith(sustain: value),
      'release' => copyWith(release: value),
      'filterEnvAmount' => copyWith(filterEnvAmount: value),
      'filterDecay' => copyWith(filterDecay: value),
      'glideMs' => copyWith(glideMs: value),
      _ => this,
    };
  }
}