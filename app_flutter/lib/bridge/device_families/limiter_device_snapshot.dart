part of '../device_snapshot.dart';

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
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return LimiterDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
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
