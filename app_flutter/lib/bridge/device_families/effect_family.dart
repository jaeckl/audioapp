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
    required this.reverbRoomSize,
    required this.reverbDamping,
    required this.reverbWet,
    required this.reverbWidth,
  }) : super(type: 'reverb');

  final double reverbRoomSize;
  final double reverbDamping;
  final double reverbWet;
  final double reverbWidth;

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
      reverbRoomSize: (params['roomSize'] as num?)?.toDouble() ?? 0.5,
      reverbDamping: (params['damping'] as num?)?.toDouble() ?? 0.3,
      reverbWet: (params['wet'] as num?)?.toDouble() ?? 0.5,
      reverbWidth: (params['width'] as num?)?.toDouble() ?? 0.5,
      outputMix: (params['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (params['outputWidth'] as num?)?.toDouble() ?? 1.0,
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
    double? reverbRoomSize,
    double? reverbDamping,
    double? reverbWet,
    double? reverbWidth,
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
      reverbRoomSize: reverbRoomSize ?? this.reverbRoomSize,
      reverbDamping: reverbDamping ?? this.reverbDamping,
      reverbWet: reverbWet ?? this.reverbWet,
      reverbWidth: reverbWidth ?? this.reverbWidth,
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
      'roomSize' => copyWith(reverbRoomSize: value),
      'damping' => copyWith(reverbDamping: value),
      'wet' => copyWith(reverbWet: value),
      'width' => copyWith(reverbWidth: value),
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
    required this.chorusDepth,
    required this.chorusRateHz,
    required this.chorusCentreDelayMs,
    required this.chorusFeedback,
  }) : super(type: 'chorus');

  final double chorusDepth;
  final double chorusRateHz;
  final double chorusCentreDelayMs;
  final double chorusFeedback;

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
      chorusDepth: (params['depth'] as num?)?.toDouble() ?? 0.3,
      chorusRateHz: (params['rateHz'] as num?)?.toDouble() ?? 0.5,
      chorusCentreDelayMs: (params['centreDelayMs'] as num?)?.toDouble() ?? 0.3,
      chorusFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.3,
      outputMix: (params['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (params['outputWidth'] as num?)?.toDouble() ?? 1.0,
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
    double? chorusDepth,
    double? chorusRateHz,
    double? chorusCentreDelayMs,
    double? chorusFeedback,
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
      chorusDepth: chorusDepth ?? this.chorusDepth,
      chorusRateHz: chorusRateHz ?? this.chorusRateHz,
      chorusCentreDelayMs: chorusCentreDelayMs ?? this.chorusCentreDelayMs,
      chorusFeedback: chorusFeedback ?? this.chorusFeedback,
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
      'depth' => copyWith(chorusDepth: value),
      'rateHz' => copyWith(chorusRateHz: value),
      'centreDelayMs' => copyWith(chorusCentreDelayMs: value),
      'feedback' => copyWith(chorusFeedback: value),
      _ => this,
    };
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
  }) : super(type: 'phaser');

  final double phaserDepth;
  final double phaserRateHz;
  final double phaserFeedback;
  final double phaserCentreFrequencyHz;

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
          (params['centreFrequencyHz'] as num?)?.toDouble() ?? 0.3,
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
