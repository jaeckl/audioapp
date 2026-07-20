part of '../device_snapshot.dart';

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
    required this.distSym,
    required this.distTone,
  }) : super(type: 'distortion');

  final double distDrive;
  final double distSym;
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
      distDrive: (params['drive'] as num?)?.toDouble() ??
          (params['distDrive'] as num?)?.toDouble() ??
          0.5,
      distSym: (params['sym'] as num?)?.toDouble() ??
          (params['distSym'] as num?)?.toDouble() ??
          0.5,
      distTone: (params['tone'] as num?)?.toDouble() ??
          (params['distTone'] as num?)?.toDouble() ??
          0.5,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (params['outputMix'] as num?)?.toDouble() ??
          1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (params['outputWidth'] as num?)?.toDouble() ??
          1.0,
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
    double? distSym,
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
      distSym: distSym ?? this.distSym,
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
      'drive' || 'distDrive' => copyWith(distDrive: value),
      'sym' || 'distSym' => copyWith(distSym: value),
      'tone' || 'distTone' => copyWith(distTone: value),
      _ => this,
    };
  }
}
