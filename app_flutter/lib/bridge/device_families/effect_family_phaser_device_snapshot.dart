part of '../device_snapshot.dart';

class PhaserDeviceSnapshot extends EffectDeviceSnapshot {
  const PhaserDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.phaserDepth,
    required this.phaserRateHz,
    required this.phaserFeedback,
    required this.phaserCentreFrequencyHz,
    this.phaserRateMode = 2,
    this.phaserWaveform = 0,
    this.phaserWaveShape = .34,
    this.phaserPhaseOffset = 0,
    this.phaserStereoPhase = .75,
    this.phaserStages = 8,
  }) : super(type: 'phaser');

  final double phaserDepth;
  final double phaserRateHz;
  final double phaserFeedback;
  final double phaserCentreFrequencyHz;
  final double phaserRateMode;
  final double phaserWaveform;
  final double phaserWaveShape;
  final double phaserPhaseOffset;
  final double phaserStereoPhase;
  final double phaserStages;

  factory PhaserDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return PhaserDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      phaserDepth: (params['depth'] as num?)?.toDouble() ?? 0.5,
      phaserRateHz: (params['rateHz'] as num?)?.toDouble() ?? 0.5,
      phaserFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.3,
      phaserCentreFrequencyHz:
          (params['centreFrequencyHz'] as num?)?.toDouble() ?? 1000.0,
      phaserRateMode: (params['rateMode'] as num?)?.toDouble() ?? 2.0,
      phaserWaveform: (params['waveform'] as num?)?.toDouble() ?? 0.0,
      phaserWaveShape: (params['waveShape'] as num?)?.toDouble() ?? .34,
      phaserPhaseOffset: (params['phaseOffset'] as num?)?.toDouble() ?? 0.0,
      phaserStereoPhase: (params['stereoPhase'] as num?)?.toDouble() ?? .75,
      phaserStages: (params['stages'] as num?)?.toDouble() ?? 8.0,
      outputMix: (params['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (params['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  PhaserDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? phaserDepth,
    double? phaserRateHz,
    double? phaserFeedback,
    double? phaserCentreFrequencyHz,
    double? phaserRateMode,
    double? phaserWaveform,
    double? phaserWaveShape,
    double? phaserPhaseOffset,
    double? phaserStereoPhase,
    double? phaserStages,
  }) {
    return PhaserDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      phaserDepth: phaserDepth ?? this.phaserDepth,
      phaserRateHz: phaserRateHz ?? this.phaserRateHz,
      phaserFeedback: phaserFeedback ?? this.phaserFeedback,
      phaserCentreFrequencyHz:
          phaserCentreFrequencyHz ?? this.phaserCentreFrequencyHz,
      phaserRateMode: phaserRateMode ?? this.phaserRateMode,
      phaserWaveform: phaserWaveform ?? this.phaserWaveform,
      phaserWaveShape: phaserWaveShape ?? this.phaserWaveShape,
      phaserPhaseOffset: phaserPhaseOffset ?? this.phaserPhaseOffset,
      phaserStereoPhase: phaserStereoPhase ?? this.phaserStereoPhase,
      phaserStages: phaserStages ?? this.phaserStages,
    );
  }

  @override
  PhaserDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'depth' => copyWith(phaserDepth: value),
      'rateHz' => copyWith(phaserRateHz: value),
      'feedback' => copyWith(phaserFeedback: value),
      'centreFrequencyHz' => copyWith(phaserCentreFrequencyHz: value),
      'rateMode' => copyWith(phaserRateMode: value),
      'waveform' => copyWith(phaserWaveform: value),
      'waveShape' => copyWith(phaserWaveShape: value),
      'phaseOffset' => copyWith(phaserPhaseOffset: value),
      'stereoPhase' => copyWith(phaserStereoPhase: value),
      'stages' => copyWith(phaserStages: value),
      _ => this,
    };
  }
}
