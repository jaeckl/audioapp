part of '../device_snapshot.dart';

class DeCracklerDeviceSnapshot extends EffectDeviceSnapshot {
  const DeCracklerDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.crackSense,
    required this.crackStrength,
    required this.crackWidth,
  }) : super(type: 'de_crackler');

  final double crackSense;
  final double crackStrength;
  final double crackWidth;

  factory DeCracklerDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DeCracklerDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      crackSense: (params['sensitivity'] as num?)?.toDouble() ?? 0.5,
      crackStrength: (params['strength'] as num?)?.toDouble() ?? 0.6,
      crackWidth: (params['width'] as num?)?.toDouble() ?? 0.4,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (params['outputMix'] as num?)?.toDouble() ??
          1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (params['outputWidth'] as num?)?.toDouble() ??
          1.0,
    );
  }

  @override
  DeCracklerDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? crackSense,
    double? crackStrength,
    double? crackWidth,
  }) {
    return DeCracklerDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      crackSense: crackSense ?? this.crackSense,
      crackStrength: crackStrength ?? this.crackStrength,
      crackWidth: crackWidth ?? this.crackWidth,
    );
  }

  @override
  DeCracklerDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'sensitivity' || 'crackSense' => copyWith(crackSense: value),
      'strength' || 'crackStrength' => copyWith(crackStrength: value),
      'width' || 'crackWidth' => copyWith(crackWidth: value),
      _ => this,
    };
  }
}
