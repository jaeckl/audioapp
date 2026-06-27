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
  });
}

class DelayDeviceSnapshot extends EffectDeviceSnapshot {
  const DelayDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.delayTimeMs,
    required this.delayFeedback,
    required this.delayMix,
  }) : super(type: 'delay');

  final double delayTimeMs;
  final double delayFeedback;
  final double delayMix;

  factory DelayDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DelayDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      delayTimeMs: (params['timeMs'] as num?)?.toDouble() ?? 250.0,
      delayFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.4,
      delayMix: (params['mix'] as num?)?.toDouble() ?? 0.5,
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
    double? delayTimeMs,
    double? delayFeedback,
    double? delayMix,
  }) {
    return DelayDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      delayTimeMs: delayTimeMs ?? this.delayTimeMs,
      delayFeedback: delayFeedback ?? this.delayFeedback,
      delayMix: delayMix ?? this.delayMix,
    );
  }

  @override
  DelayDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'timeMs' => copyWith(delayTimeMs: value),
      'feedback' => copyWith(delayFeedback: value),
      'mix' => copyWith(delayMix: value),
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
    required this.reverbRoomSize,
    required this.reverbDamping,
    required this.reverbWetLevel,
    required this.reverbDryLevel,
    required this.reverbWidth,
  }) : super(type: 'reverb');

  final double reverbRoomSize;
  final double reverbDamping;
  final double reverbWetLevel;
  final double reverbDryLevel;
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
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      reverbRoomSize: (params['roomSize'] as num?)?.toDouble() ?? 0.5,
      reverbDamping: (params['damping'] as num?)?.toDouble() ?? 0.3,
      reverbWetLevel: (params['wetLevel'] as num?)?.toDouble() ?? 0.4,
      reverbDryLevel: (params['dryLevel'] as num?)?.toDouble() ?? 0.6,
      reverbWidth: (params['width'] as num?)?.toDouble() ?? 0.5,
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
    double? reverbRoomSize,
    double? reverbDamping,
    double? reverbWetLevel,
    double? reverbDryLevel,
    double? reverbWidth,
  }) {
    return ReverbDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      reverbRoomSize: reverbRoomSize ?? this.reverbRoomSize,
      reverbDamping: reverbDamping ?? this.reverbDamping,
      reverbWetLevel: reverbWetLevel ?? this.reverbWetLevel,
      reverbDryLevel: reverbDryLevel ?? this.reverbDryLevel,
      reverbWidth: reverbWidth ?? this.reverbWidth,
    );
  }

  @override
  ReverbDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'roomSize' => copyWith(reverbRoomSize: value),
      'damping' => copyWith(reverbDamping: value),
      'wetLevel' => copyWith(reverbWetLevel: value),
      'dryLevel' => copyWith(reverbDryLevel: value),
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
    required this.chorusDepth,
    required this.chorusRateHz,
    required this.chorusMix,
    required this.chorusCentreDelayMs,
    required this.chorusFeedback,
  }) : super(type: 'chorus');

  final double chorusDepth;
  final double chorusRateHz;
  final double chorusMix;
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
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      chorusDepth: (params['depth'] as num?)?.toDouble() ?? 0.3,
      chorusRateHz: (params['rateHz'] as num?)?.toDouble() ?? 0.5,
      chorusMix: (params['mix'] as num?)?.toDouble() ?? 0.4,
      chorusCentreDelayMs: (params['centreDelayMs'] as num?)?.toDouble() ?? 0.3,
      chorusFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.3,
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
    double? chorusDepth,
    double? chorusRateHz,
    double? chorusMix,
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
      chorusDepth: chorusDepth ?? this.chorusDepth,
      chorusRateHz: chorusRateHz ?? this.chorusRateHz,
      chorusMix: chorusMix ?? this.chorusMix,
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
      'depth' => copyWith(chorusDepth: value),
      'rateHz' => copyWith(chorusRateHz: value),
      'mix' => copyWith(chorusMix: value),
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
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      phaserDepth: (params['depth'] as num?)?.toDouble() ?? 0.5,
      phaserRateHz: (params['rateHz'] as num?)?.toDouble() ?? 0.5,
      phaserFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.3,
      phaserCentreFrequencyHz: (params['centreFrequencyHz'] as num?)?.toDouble() ?? 0.3,
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
      phaserDepth: phaserDepth ?? this.phaserDepth,
      phaserRateHz: phaserRateHz ?? this.phaserRateHz,
      phaserFeedback: phaserFeedback ?? this.phaserFeedback,
      phaserCentreFrequencyHz: phaserCentreFrequencyHz ?? this.phaserCentreFrequencyHz,
    );
  }

  @override
  PhaserDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
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
    required this.bcRate,
    required this.bcBits,
    required this.bcMix,
  }) : super(type: 'bitcrusher');

  final double bcRate;
  final double bcBits;
  final double bcMix;

  factory BitcrusherDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return BitcrusherDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      bcRate: (params['rate'] as num?)?.toDouble() ?? 0.5,
      bcBits: (params['bits'] as num?)?.toDouble() ?? 8.0,
      bcMix: (params['mix'] as num?)?.toDouble() ?? 0.5,
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
    double? bcRate,
    double? bcBits,
    double? bcMix,
  }) {
    return BitcrusherDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      bcRate: bcRate ?? this.bcRate,
      bcBits: bcBits ?? this.bcBits,
      bcMix: bcMix ?? this.bcMix,
    );
  }

  @override
  BitcrusherDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'bcRate' => copyWith(bcRate: value),
      'bcBits' => copyWith(bcBits: value),
      'bcMix' => copyWith(bcMix: value),
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
    required this.distDrive,
    required this.distTone,
    required this.distMix,
  }) : super(type: 'distortion');

  final double distDrive;
  final double distTone;
  final double distMix;

  factory DistortionDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DistortionDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      distDrive: (params['drive'] as num?)?.toDouble() ?? 0.5,
      distTone: (params['tone'] as num?)?.toDouble() ?? 0.5,
      distMix: (params['mix'] as num?)?.toDouble() ?? 0.5,
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
    double? distDrive,
    double? distTone,
    double? distMix,
  }) {
    return DistortionDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      distDrive: distDrive ?? this.distDrive,
      distTone: distTone ?? this.distTone,
      distMix: distMix ?? this.distMix,
    );
  }

  @override
  DistortionDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'distDrive' => copyWith(distDrive: value),
      'distTone' => copyWith(distTone: value),
      'distMix' => copyWith(distMix: value),
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
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      tremDepth: (params['depth'] as num?)?.toDouble() ?? 0.5,
      tremRate: (params['rateHz'] as num?)?.toDouble() ?? 5.0,
      tremShape: (params['shape'] as num?)?.toDouble() ?? 0.0,
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
      'tremDepth' => copyWith(tremDepth: value),
      'tremRate' => copyWith(tremRate: value),
      'tremShape' => copyWith(tremShape: value),
      _ => this,
    };
  }
}