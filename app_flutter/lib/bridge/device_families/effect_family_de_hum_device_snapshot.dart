part of '../device_snapshot.dart';

class DeHumDeviceSnapshot extends EffectDeviceSnapshot {
  const DeHumDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.humMains,
    required this.humDepth,
    required this.humHarmonics,
  }) : super(type: 'de_hum');

  /// 0 = 50 Hz, 1 = 60 Hz
  final double humMains;
  final double humDepth;
  final double humHarmonics;

  factory DeHumDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DeHumDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      humMains: (params['mainsFreq'] as num?)?.toDouble() ?? 0.0,
      humDepth: (params['depth'] as num?)?.toDouble() ?? 0.7,
      humHarmonics: (params['harmonics'] as num?)?.toDouble() ?? 0.4,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (params['outputMix'] as num?)?.toDouble() ??
          1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (params['outputWidth'] as num?)?.toDouble() ??
          1.0,
    );
  }

  @override
  DeHumDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? humMains,
    double? humDepth,
    double? humHarmonics,
  }) {
    return DeHumDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      humMains: humMains ?? this.humMains,
      humDepth: humDepth ?? this.humDepth,
      humHarmonics: humHarmonics ?? this.humHarmonics,
    );
  }

  @override
  DeHumDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'mainsFreq' || 'humMains' => copyWith(humMains: value),
      'depth' || 'humDepth' => copyWith(humDepth: value),
      'harmonics' || 'humHarmonics' => copyWith(humHarmonics: value),
      _ => this,
    };
  }
}
