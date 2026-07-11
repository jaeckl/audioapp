part of '../device_snapshot.dart';

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
