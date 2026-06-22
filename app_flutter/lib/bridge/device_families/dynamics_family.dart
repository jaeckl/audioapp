part of '../device_snapshots.dart';

sealed class DynamicsDeviceSnapshot extends DeviceSnapshot {
  const DynamicsDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.inputGain,
  });

  final double inputGain;
}

class GateDeviceSnapshot extends DynamicsDeviceSnapshot {
  const GateDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.gateThreshold,
    required this.gateAttack,
    required this.gateRelease,
    required this.gateHold,
    required this.gateRange,
  }) : super(type: 'gate');

  final double gateThreshold;
  final double gateAttack;
  final double gateRelease;
  final double gateHold;
  final double gateRange;

  factory GateDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return GateDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      gateThreshold: (params['gateThreshold'] as num?)?.toDouble() ?? 0.45,
      gateAttack: (params['gateAttack'] as num?)?.toDouble() ?? 0.25,
      gateRelease: (params['gateRelease'] as num?)?.toDouble() ?? 0.50,
      gateHold: (params['gateHold'] as num?)?.toDouble() ?? 0.20,
      gateRange: (params['gateRange'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  GateDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? gateThreshold,
    double? gateAttack,
    double? gateRelease,
    double? gateHold,
    double? gateRange,
  }) {
    return GateDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      gateThreshold: gateThreshold ?? this.gateThreshold,
      gateAttack: gateAttack ?? this.gateAttack,
      gateRelease: gateRelease ?? this.gateRelease,
      gateHold: gateHold ?? this.gateHold,
      gateRange: gateRange ?? this.gateRange,
    );
  }

  @override
  GateDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'gateThreshold' => copyWith(gateThreshold: value.clamp(0.0, 1.0)),
      'gateAttack' => copyWith(gateAttack: value.clamp(0.0, 1.0)),
      'gateRelease' => copyWith(gateRelease: value.clamp(0.0, 1.0)),
      'gateHold' => copyWith(gateHold: value.clamp(0.0, 1.0)),
      'gateRange' => copyWith(gateRange: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class CompressorDeviceSnapshot extends DynamicsDeviceSnapshot {
  const CompressorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.compThreshold,
    required this.compRatio,
    required this.compAttack,
    required this.compRelease,
    required this.compKnee,
    required this.compMakeup,
  }) : super(type: 'compressor');

  final double compThreshold;
  final double compRatio;
  final double compAttack;
  final double compRelease;
  final double compKnee;
  final double compMakeup;

  factory CompressorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return CompressorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      compThreshold: (params['compThreshold'] as num?)?.toDouble() ?? 0.55,
      compRatio: (params['compRatio'] as num?)?.toDouble() ?? 0.50,
      compAttack: (params['compAttack'] as num?)?.toDouble() ?? 0.20,
      compRelease: (params['compRelease'] as num?)?.toDouble() ?? 0.55,
      compKnee: (params['compKnee'] as num?)?.toDouble() ?? 0.25,
      compMakeup: (params['compMakeup'] as num?)?.toDouble() ?? 0.35,
    );
  }

  @override
  CompressorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? compThreshold,
    double? compRatio,
    double? compAttack,
    double? compRelease,
    double? compKnee,
    double? compMakeup,
  }) {
    return CompressorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      compThreshold: compThreshold ?? this.compThreshold,
      compRatio: compRatio ?? this.compRatio,
      compAttack: compAttack ?? this.compAttack,
      compRelease: compRelease ?? this.compRelease,
      compKnee: compKnee ?? this.compKnee,
      compMakeup: compMakeup ?? this.compMakeup,
    );
  }

  @override
  CompressorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'compThreshold' => copyWith(compThreshold: value.clamp(0.0, 1.0)),
      'compRatio' => copyWith(compRatio: value.clamp(0.0, 1.0)),
      'compAttack' => copyWith(compAttack: value.clamp(0.0, 1.0)),
      'compRelease' => copyWith(compRelease: value.clamp(0.0, 1.0)),
      'compKnee' => copyWith(compKnee: value.clamp(0.0, 1.0)),
      'compMakeup' => copyWith(compMakeup: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class ExpanderDeviceSnapshot extends DynamicsDeviceSnapshot {
  const ExpanderDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.expandThreshold,
    required this.expandRatio,
    required this.expandAttack,
    required this.expandRelease,
    required this.expandRange,
  }) : super(type: 'expander');

  final double expandThreshold;
  final double expandRatio;
  final double expandAttack;
  final double expandRelease;
  final double expandRange;

  factory ExpanderDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ExpanderDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      expandThreshold: (params['expandThreshold'] as num?)?.toDouble() ?? 0.40,
      expandRatio: (params['expandRatio'] as num?)?.toDouble() ?? 0.45,
      expandAttack: (params['expandAttack'] as num?)?.toDouble() ?? 0.25,
      expandRelease: (params['expandRelease'] as num?)?.toDouble() ?? 0.55,
      expandRange: (params['expandRange'] as num?)?.toDouble() ?? 0.15,
    );
  }

  @override
  ExpanderDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? expandThreshold,
    double? expandRatio,
    double? expandAttack,
    double? expandRelease,
    double? expandRange,
  }) {
    return ExpanderDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      expandThreshold: expandThreshold ?? this.expandThreshold,
      expandRatio: expandRatio ?? this.expandRatio,
      expandAttack: expandAttack ?? this.expandAttack,
      expandRelease: expandRelease ?? this.expandRelease,
      expandRange: expandRange ?? this.expandRange,
    );
  }

  @override
  ExpanderDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'expandThreshold' => copyWith(expandThreshold: value.clamp(0.0, 1.0)),
      'expandRatio' => copyWith(expandRatio: value.clamp(0.0, 1.0)),
      'expandAttack' => copyWith(expandAttack: value.clamp(0.0, 1.0)),
      'expandRelease' => copyWith(expandRelease: value.clamp(0.0, 1.0)),
      'expandRange' => copyWith(expandRange: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class LimiterDeviceSnapshot extends DynamicsDeviceSnapshot {
  const LimiterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.limitCeiling,
    required this.limitAttack,
    required this.limitRelease,
    required this.limitKnee,
    required this.limitDrive,
    required this.limitMakeup,
  }) : super(type: 'limiter');

  final double limitCeiling;
  final double limitAttack;
  final double limitRelease;
  final double limitKnee;
  final double limitDrive;
  final double limitMakeup;

  factory LimiterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return LimiterDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      limitCeiling: (params['limitCeiling'] as num?)?.toDouble() ?? 0.85,
      limitAttack: (params['limitAttack'] as num?)?.toDouble() ?? 0.10,
      limitRelease: (params['limitRelease'] as num?)?.toDouble() ?? 0.40,
      limitKnee: (params['limitKnee'] as num?)?.toDouble() ?? 0.0,
      limitDrive: (params['limitDrive'] as num?)?.toDouble() ?? 0.0,
      limitMakeup: (params['limitMakeup'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  LimiterDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? limitCeiling,
    double? limitAttack,
    double? limitRelease,
    double? limitKnee,
    double? limitDrive,
    double? limitMakeup,
  }) {
    return LimiterDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      limitCeiling: limitCeiling ?? this.limitCeiling,
      limitAttack: limitAttack ?? this.limitAttack,
      limitRelease: limitRelease ?? this.limitRelease,
      limitKnee: limitKnee ?? this.limitKnee,
      limitDrive: limitDrive ?? this.limitDrive,
      limitMakeup: limitMakeup ?? this.limitMakeup,
    );
  }

  @override
  LimiterDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'limitCeiling' => copyWith(limitCeiling: value.clamp(0.0, 1.0)),
      'limitAttack' => copyWith(limitAttack: value.clamp(0.0, 1.0)),
      'limitRelease' => copyWith(limitRelease: value.clamp(0.0, 1.0)),
      'limitKnee' => copyWith(limitKnee: value.clamp(0.0, 1.0)),
      'limitDrive' => copyWith(limitDrive: value.clamp(0.0, 1.0)),
      'limitMakeup' => copyWith(limitMakeup: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}