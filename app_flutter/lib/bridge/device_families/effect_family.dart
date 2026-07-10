part of '../device_snapshot.dart';

sealed class EffectDeviceSnapshot extends DeviceSnapshot {
  const EffectDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    this.outputMix = 1.0,
    this.outputWidth = 1.0,
  });

  final double outputMix;
  final double outputWidth;
}

class DelayDeviceSnapshot extends EffectDeviceSnapshot {
  const DelayDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.delayTimeMs,
    required this.delayFeedback,
    this.delayTimeMode = 0,
    this.delayNoteCount = 1,
    this.delayBlurMode = 0,
    this.delayBlurAmount = 0.5,
    this.delayInputDucking = 0,
    this.delayLowCutHz = 20,
    this.delayHighCutHz = 20000,
  }) : super(type: 'delay');

  final double delayTimeMs;
  final double delayFeedback;
  final double delayTimeMode;
  final double delayNoteCount;
  final double delayBlurMode;
  final double delayBlurAmount;
  final double delayInputDucking;
  final double delayLowCutHz;
  final double delayHighCutHz;

  factory DelayDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DelayDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      delayTimeMs: (params['timeMs'] as num?)?.toDouble() ?? 250.0,
      delayFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.4,
      delayTimeMode: (params['timeMode'] as num?)?.toDouble() ?? 0.0,
      delayNoteCount: (params['noteCount'] as num?)?.toDouble() ?? 1.0,
      delayBlurMode: (params['blurMode'] as num?)?.toDouble() ?? 0.0,
      delayBlurAmount: (params['blurAmount'] as num?)?.toDouble() ?? 0.5,
      delayInputDucking: (params['inputDucking'] as num?)?.toDouble() ?? 0.0,
      delayLowCutHz: (params['lowCutHz'] as num?)?.toDouble() ?? 20.0,
      delayHighCutHz: (params['highCutHz'] as num?)?.toDouble() ?? 20000.0,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (params['outputMix'] as num?)?.toDouble() ??
          1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (params['outputWidth'] as num?)?.toDouble() ??
          1.0,
    );
  }

  @override
  DelayDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? delayTimeMs,
    double? delayFeedback,
    double? delayTimeMode,
    double? delayNoteCount,
    double? delayBlurMode,
    double? delayBlurAmount,
    double? delayInputDucking,
    double? delayLowCutHz,
    double? delayHighCutHz,
  }) {
    return DelayDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      delayTimeMs: delayTimeMs ?? this.delayTimeMs,
      delayFeedback: delayFeedback ?? this.delayFeedback,
      delayTimeMode: delayTimeMode ?? this.delayTimeMode,
      delayNoteCount: delayNoteCount ?? this.delayNoteCount,
      delayBlurMode: delayBlurMode ?? this.delayBlurMode,
      delayBlurAmount: delayBlurAmount ?? this.delayBlurAmount,
      delayInputDucking: delayInputDucking ?? this.delayInputDucking,
      delayLowCutHz: delayLowCutHz ?? this.delayLowCutHz,
      delayHighCutHz: delayHighCutHz ?? this.delayHighCutHz,
    );
  }

  @override
  DelayDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'timeMs' => copyWith(delayTimeMs: value),
      'feedback' => copyWith(delayFeedback: value),
      'timeMode' => copyWith(delayTimeMode: value),
      'noteCount' => copyWith(delayNoteCount: value),
      'blurMode' => copyWith(delayBlurMode: value),
      'blurAmount' => copyWith(delayBlurAmount: value),
      'inputDucking' => copyWith(delayInputDucking: value),
      'lowCutHz' => copyWith(delayLowCutHz: value),
      'highCutHz' => copyWith(delayHighCutHz: value),
      _ => this,
    };
  }
}

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

class ChorusDeviceSnapshot extends EffectDeviceSnapshot {
  const ChorusDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    this.modeMorph = 0,
    this.classic = const [0.286, 0.25, 0.30, 0.0, 0.5, 0.0],
    this.ensemble = const [0.25, 0.50, 0.50, 0.65, 0.25, 0.65],
    this.dimension = const [0.50, 0.35, 0.80, 0.25, 0.0, 0.90],
    this.drift = const [0.30, 0.50, 0.40, 0.40, 0.70, 0.60],
  }) : super(type: 'chorus');

  final double modeMorph;
  final List<double> classic;
  final List<double> ensemble;
  final List<double> dimension;
  final List<double> drift;

  double get chorusRateHz => 0.1 + classic[0] * 4.9;
  double get chorusDepth => classic[1];
  double get chorusCentreDelayMs => 2 + classic[2] * 18;
  double get chorusFeedback => classic[3] * 0.8;

  static List<double> _bank(
    dynamic value,
    List<double> fallback,
  ) {
    if (value is! List || value.length < 6) return List<double>.from(fallback);
    return List<double>.generate(
      6,
      (index) => (value[index] as num?)?.toDouble() ?? fallback[index],
    );
  }

  factory ChorusDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ChorusDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      modeMorph: (params['modeMorph'] as num?)?.toDouble() ?? 0,
      classic: params['classic'] is List
          ? _bank(params['classic'], const [0.286, 0.25, 0.30, 0, 0.5, 0])
          : <double>[
              (((params['rateHz'] as num?)?.toDouble() ?? 1.5) - 0.1) / 4.9,
              (params['depth'] as num?)?.toDouble() ?? 0.25,
              ((((params['centreDelayMs'] as num?)?.toDouble() ?? 7) - 2) / 18)
                  .clamp(0.0, 1.0),
              ((params['feedback'] as num?)?.toDouble() ?? 0) / 0.8,
              0.5,
              0,
            ],
      ensemble:
          _bank(params['ensemble'], const [0.25, 0.50, 0.50, 0.65, 0.25, 0.65]),
      dimension:
          _bank(params['dimension'], const [0.50, 0.35, 0.80, 0.25, 0.0, 0.90]),
      drift: _bank(params['drift'], const [0.30, 0.50, 0.40, 0.40, 0.70, 0.60]),
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ?? 0.4,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  ChorusDeviceSnapshot copyWith({
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
    List<double>? classic,
    List<double>? ensemble,
    List<double>? dimension,
    List<double>? drift,
  }) {
    return ChorusDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      modeMorph: modeMorph ?? this.modeMorph,
      classic: classic ?? this.classic,
      ensemble: ensemble ?? this.ensemble,
      dimension: dimension ?? this.dimension,
      drift: drift ?? this.drift,
    );
  }

  @override
  ChorusDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'modeMorph' => copyWith(modeMorph: value),
      'classicRate' => copyWith(classic: _withBankValue(classic, 0, value)),
      'classicDepth' => copyWith(classic: _withBankValue(classic, 1, value)),
      'classicDelay' => copyWith(classic: _withBankValue(classic, 2, value)),
      'classicFeedback' => copyWith(classic: _withBankValue(classic, 3, value)),
      'classicPhase' => copyWith(classic: _withBankValue(classic, 4, value)),
      'classicShape' => copyWith(classic: _withBankValue(classic, 5, value)),
      'ensembleRate' => copyWith(ensemble: _withBankValue(ensemble, 0, value)),
      'ensembleDepth' => copyWith(ensemble: _withBankValue(ensemble, 1, value)),
      'ensembleVoices' =>
        copyWith(ensemble: _withBankValue(ensemble, 2, value)),
      'ensembleSpread' =>
        copyWith(ensemble: _withBankValue(ensemble, 3, value)),
      'ensembleDrift' => copyWith(ensemble: _withBankValue(ensemble, 4, value)),
      'ensembleTone' => copyWith(ensemble: _withBankValue(ensemble, 5, value)),
      'dimensionAmount' =>
        copyWith(dimension: _withBankValue(dimension, 0, value)),
      'dimensionDelay' =>
        copyWith(dimension: _withBankValue(dimension, 1, value)),
      'dimensionSpread' =>
        copyWith(dimension: _withBankValue(dimension, 2, value)),
      'dimensionMotion' =>
        copyWith(dimension: _withBankValue(dimension, 3, value)),
      'dimensionLowCut' =>
        copyWith(dimension: _withBankValue(dimension, 4, value)),
      'dimensionHighCut' =>
        copyWith(dimension: _withBankValue(dimension, 5, value)),
      'driftSpeed' => copyWith(drift: _withBankValue(drift, 0, value)),
      'driftDepth' => copyWith(drift: _withBankValue(drift, 1, value)),
      'driftWander' => copyWith(drift: _withBankValue(drift, 2, value)),
      'driftDelay' => copyWith(drift: _withBankValue(drift, 3, value)),
      'driftStereo' => copyWith(drift: _withBankValue(drift, 4, value)),
      'driftTone' => copyWith(drift: _withBankValue(drift, 5, value)),
      _ => this,
    };
  }

  static List<double> _withBankValue(
    List<double> bank,
    int index,
    double value,
  ) {
    final copy = List<double>.from(bank);
    copy[index] = value;
    return copy;
  }
}

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

class BitcrusherDeviceSnapshot extends EffectDeviceSnapshot {
  const BitcrusherDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.bcRate,
    required this.bcBits,
  }) : super(type: 'bitcrusher');

  final double bcRate;
  final double bcBits;

  factory BitcrusherDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return BitcrusherDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      bcRate: (params['rate'] as num?)?.toDouble() ?? 0.5,
      bcBits: (params['bits'] as num?)?.toDouble() ?? 8.0,
      outputMix: (params['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (params['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  BitcrusherDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? bcRate,
    double? bcBits,
  }) {
    return BitcrusherDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      bcRate: bcRate ?? this.bcRate,
      bcBits: bcBits ?? this.bcBits,
    );
  }

  @override
  BitcrusherDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'rate' => copyWith(bcRate: value),
      'bits' => copyWith(bcBits: value),
      _ => this,
    };
  }
}

class DistortionDeviceSnapshot extends EffectDeviceSnapshot {
  const DistortionDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.distDrive,
    required this.distTone,
  }) : super(type: 'distortion');

  final double distDrive;
  final double distTone;

  factory DistortionDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DistortionDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      distDrive: (params['drive'] as num?)?.toDouble() ?? 0.5,
      distTone: (params['tone'] as num?)?.toDouble() ?? 0.5,
      outputMix: (params['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (params['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  DistortionDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? distDrive,
    double? distTone,
  }) {
    return DistortionDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      distDrive: distDrive ?? this.distDrive,
      distTone: distTone ?? this.distTone,
    );
  }

  @override
  DistortionDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'drive' => copyWith(distDrive: value),
      'tone' => copyWith(distTone: value),
      _ => this,
    };
  }
}

class TremoloDeviceSnapshot extends EffectDeviceSnapshot {
  const TremoloDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.tremDepth,
    required this.tremRate,
    required this.tremShape,
  }) : super(type: 'tremolo');

  final double tremDepth;
  final double tremRate;
  final double tremShape;

  factory TremoloDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return TremoloDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      tremDepth: (params['depth'] as num?)?.toDouble() ?? 0.5,
      tremRate: (params['rateHz'] as num?)?.toDouble() ?? 5.0,
      tremShape: (params['shape'] as num?)?.toDouble() ?? 0.0,
      outputMix: (params['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (params['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  TremoloDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? tremDepth,
    double? tremRate,
    double? tremShape,
  }) {
    return TremoloDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      tremDepth: tremDepth ?? this.tremDepth,
      tremRate: tremRate ?? this.tremRate,
      tremShape: tremShape ?? this.tremShape,
    );
  }

  @override
  TremoloDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'depth' => copyWith(tremDepth: value),
      'rateHz' => copyWith(tremRate: value),
      'shape' => copyWith(tremShape: value),
      _ => this,
    };
  }
}

class StutterDeviceSnapshot extends EffectDeviceSnapshot {
  const StutterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.trigger,
    required this.captureMs,
    required this.rateSync,
    required this.rateBeats,
    required this.rateMs,
    required this.windowMs,
    required this.position,
    required this.gate,
    required this.fadeMs,
    required this.direction,
    required this.mix,
    required this.duck,
    required this.outputGain,
  }) : super(type: 'stutter_fx');

  final double trigger;
  final double captureMs;
  final double rateSync;
  final double rateBeats;
  final double rateMs;
  final double windowMs;
  final double position;
  final double gate;
  final double fadeMs;
  final double direction;
  final double mix;
  final double duck;
  final double outputGain;

  factory StutterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return StutterDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      trigger: (params['trigger'] as num?)?.toDouble() ?? 0.0,
      captureMs: (params['captureMs'] as num?)?.toDouble() ?? 500.0,
      rateSync: (params['rateSync'] as num?)?.toDouble() ?? 1.0,
      rateBeats: (params['rateBeats'] as num?)?.toDouble() ?? 0.25,
      rateMs: (params['rateMs'] as num?)?.toDouble() ?? 125.0,
      windowMs: (params['windowMs'] as num?)?.toDouble() ?? 80.0,
      position: (params['position'] as num?)?.toDouble() ?? 0.0,
      gate: (params['gate'] as num?)?.toDouble() ?? 0.85,
      fadeMs: (params['fadeMs'] as num?)?.toDouble() ?? 3.0,
      direction: (params['direction'] as num?)?.toDouble() ?? 0.0,
      mix: (params['mix'] as num?)?.toDouble() ?? 1.0,
      duck: (params['duck'] as num?)?.toDouble() ?? 0.45,
      outputGain: (params['outputGain'] as num?)?.toDouble() ?? 1.0,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  StutterDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? trigger,
    double? captureMs,
    double? rateSync,
    double? rateBeats,
    double? rateMs,
    double? windowMs,
    double? position,
    double? gate,
    double? fadeMs,
    double? direction,
    double? mix,
    double? duck,
    double? outputGain,
  }) {
    return StutterDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      trigger: trigger ?? this.trigger,
      captureMs: captureMs ?? this.captureMs,
      rateSync: rateSync ?? this.rateSync,
      rateBeats: rateBeats ?? this.rateBeats,
      rateMs: rateMs ?? this.rateMs,
      windowMs: windowMs ?? this.windowMs,
      position: position ?? this.position,
      gate: gate ?? this.gate,
      fadeMs: fadeMs ?? this.fadeMs,
      direction: direction ?? this.direction,
      mix: mix ?? this.mix,
      duck: duck ?? this.duck,
      outputGain: outputGain ?? this.outputGain,
    );
  }

  @override
  StutterDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'trigger' => copyWith(trigger: value),
      'captureMs' => copyWith(captureMs: value),
      'rateSync' => copyWith(rateSync: value),
      'rateBeats' => copyWith(rateBeats: value),
      'rateMs' => copyWith(rateMs: value),
      'windowMs' => copyWith(windowMs: value),
      'position' => copyWith(position: value),
      'gate' => copyWith(gate: value),
      'fadeMs' => copyWith(fadeMs: value),
      'direction' => copyWith(direction: value),
      'mix' => copyWith(mix: value),
      'duck' => copyWith(duck: value),
      'outputGain' => copyWith(outputGain: value),
      _ => this,
    };
  }
}
