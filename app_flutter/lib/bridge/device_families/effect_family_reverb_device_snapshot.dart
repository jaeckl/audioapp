part of '../device_snapshot.dart';

class ReverbDeviceSnapshot extends EffectDeviceSnapshot {
  const ReverbDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    this.modeMorph = 2,
    this.decay = .56,
    this.preDelay = .112,
    this.size = .64,
    this.diffusion = .78,
    this.damping = .68,
    this.modulation = .18,
    this.lowCut = .26,
    this.highCut = .86,
    this.ducking = .25,
    this.freeze = 0,
  }) : super(type: 'reverb');

  final double modeMorph;
  final double decay;
  final double preDelay;
  final double size;
  final double diffusion;
  final double damping;
  final double modulation;
  final double lowCut;
  final double highCut;
  final double ducking;
  final double freeze;

  double get reverbRoomSize => size;
  double get reverbDamping => damping;
  double get reverbWet => outputMix;
  double get reverbWidth => outputWidth;

  factory ReverbDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ReverbDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      modeMorph: (params['modeMorph'] as num?)?.toDouble() ?? 2,
      decay: (params['decay'] as num?)?.toDouble() ??
          (.25 + ((params['roomSize'] as num?)?.toDouble() ?? .5) * .55),
      preDelay: (params['preDelay'] as num?)?.toDouble() ?? .112,
      size: (params['size'] as num?)?.toDouble() ??
          (params['roomSize'] as num?)?.toDouble() ??
          .64,
      diffusion: (params['diffusion'] as num?)?.toDouble() ?? .78,
      damping: (params['damping'] as num?)?.toDouble() ?? .68,
      modulation: (params['modulation'] as num?)?.toDouble() ?? .18,
      lowCut: (params['lowCut'] as num?)?.toDouble() ?? .26,
      highCut: (params['highCut'] as num?)?.toDouble() ?? .86,
      ducking: (params['ducking'] as num?)?.toDouble() ?? .25,
      freeze: (params['freeze'] as num?)?.toDouble() ?? 0,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ?? .35,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  ReverbDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? modeMorph,
    double? decay,
    double? preDelay,
    double? size,
    double? diffusion,
    double? damping,
    double? modulation,
    double? lowCut,
    double? highCut,
    double? ducking,
    double? freeze,
  }) {
    return ReverbDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      modeMorph: modeMorph ?? this.modeMorph,
      decay: decay ?? this.decay,
      preDelay: preDelay ?? this.preDelay,
      size: size ?? this.size,
      diffusion: diffusion ?? this.diffusion,
      damping: damping ?? this.damping,
      modulation: modulation ?? this.modulation,
      lowCut: lowCut ?? this.lowCut,
      highCut: highCut ?? this.highCut,
      ducking: ducking ?? this.ducking,
      freeze: freeze ?? this.freeze,
    );
  }

  @override
  ReverbDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'modeMorph' => copyWith(modeMorph: value.clamp(0, 3)),
      'decay' => copyWith(decay: value.clamp(0, 1)),
      'preDelay' => copyWith(preDelay: value.clamp(0, 1)),
      'size' => copyWith(size: value.clamp(0, 1)),
      'diffusion' => copyWith(diffusion: value.clamp(0, 1)),
      'damping' => copyWith(damping: value.clamp(0, 1)),
      'modulation' => copyWith(modulation: value.clamp(0, 1)),
      'lowCut' => copyWith(lowCut: value.clamp(0, 1)),
      'highCut' => copyWith(highCut: value.clamp(0, 1)),
      'ducking' => copyWith(ducking: value.clamp(0, 1)),
      'freeze' => copyWith(freeze: value.clamp(0, 1)),
      'roomSize' => copyWith(size: value.clamp(0, 1)),
      'wet' => copyWith(outputMix: value.clamp(0, 1)),
      'width' => copyWith(outputWidth: value.clamp(0, 1)),
      _ => this,
    };
  }
}
