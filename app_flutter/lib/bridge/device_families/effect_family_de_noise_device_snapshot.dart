part of '../device_snapshot.dart';

class DeNoiseDeviceSnapshot extends EffectDeviceSnapshot {
  const DeNoiseDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.dnThresh,
    required this.dnReduce,
    required this.dnSmooth,
  }) : super(type: 'de_noise');

  final double dnThresh;
  final double dnReduce;
  final double dnSmooth;

  factory DeNoiseDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DeNoiseDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      dnThresh: (params['threshold'] as num?)?.toDouble() ?? 0.35,
      dnReduce: (params['reduction'] as num?)?.toDouble() ?? 0.5,
      dnSmooth: (params['smoothing'] as num?)?.toDouble() ?? 0.4,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (params['outputMix'] as num?)?.toDouble() ??
          1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (params['outputWidth'] as num?)?.toDouble() ??
          1.0,
    );
  }

  @override
  DeNoiseDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? dnThresh,
    double? dnReduce,
    double? dnSmooth,
  }) {
    return DeNoiseDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      dnThresh: dnThresh ?? this.dnThresh,
      dnReduce: dnReduce ?? this.dnReduce,
      dnSmooth: dnSmooth ?? this.dnSmooth,
    );
  }

  @override
  DeNoiseDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'threshold' || 'dnThresh' => copyWith(dnThresh: value),
      'reduction' || 'dnReduce' => copyWith(dnReduce: value),
      'smoothing' || 'dnSmooth' => copyWith(dnSmooth: value),
      _ => this,
    };
  }
}
