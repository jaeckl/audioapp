part of '../device_snapshot.dart';

class FilterDeviceSnapshot extends FrequencyFxDeviceSnapshot {
  const FilterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.ffxCutoff,
    required this.ffxResonance,
    required this.ffxFilterMode,
  }) : super(type: 'filter');

  final double ffxCutoff;
  final double ffxResonance;
  final double ffxFilterMode;

  factory FilterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return FilterDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      ffxCutoff: (params['ffxCutoff'] as num?)?.toDouble() ?? 0.6,
      ffxResonance: (params['ffxResonance'] as num?)?.toDouble() ?? 0.3,
      ffxFilterMode: (params['ffxFilterMode'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  FilterDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? ffxCutoff,
    double? ffxResonance,
    double? ffxFilterMode,
  }) {
    return FilterDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      ffxCutoff: ffxCutoff ?? this.ffxCutoff,
      ffxResonance: ffxResonance ?? this.ffxResonance,
      ffxFilterMode: ffxFilterMode ?? this.ffxFilterMode,
    );
  }

  @override
  FilterDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'ffxCutoff' => copyWith(ffxCutoff: value.clamp(0.0, 1.0)),
      'ffxResonance' => copyWith(ffxResonance: value.clamp(0.0, 1.0)),
      'ffxFilterMode' => copyWith(ffxFilterMode: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
