part of '../device_snapshot.dart';

class DeEsserDeviceSnapshot extends EffectDeviceSnapshot {
  const DeEsserDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.deFreq,
    required this.deThresh,
    required this.deAmount,
    required this.deListen,
  }) : super(type: 'de_esser');

  final double deFreq;
  final double deThresh;
  final double deAmount;
  final double deListen;

  factory DeEsserDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DeEsserDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      deFreq: (params['freq'] as num?)?.toDouble() ?? 0.55,
      deThresh: (params['threshold'] as num?)?.toDouble() ?? 0.45,
      deAmount: (params['amount'] as num?)?.toDouble() ?? 0.5,
      deListen: (params['listen'] as num?)?.toDouble() ?? 0.0,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (params['outputMix'] as num?)?.toDouble() ??
          1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (params['outputWidth'] as num?)?.toDouble() ??
          1.0,
    );
  }

  @override
  DeEsserDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? deFreq,
    double? deThresh,
    double? deAmount,
    double? deListen,
  }) {
    return DeEsserDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      deFreq: deFreq ?? this.deFreq,
      deThresh: deThresh ?? this.deThresh,
      deAmount: deAmount ?? this.deAmount,
      deListen: deListen ?? this.deListen,
    );
  }

  @override
  DeEsserDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'freq' || 'deFreq' => copyWith(deFreq: value),
      'threshold' || 'deThresh' => copyWith(deThresh: value),
      'amount' || 'deAmount' => copyWith(deAmount: value),
      'listen' || 'deListen' => copyWith(deListen: value),
      _ => this,
    };
  }
}
