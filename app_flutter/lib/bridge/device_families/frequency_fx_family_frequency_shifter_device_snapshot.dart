part of '../device_snapshot.dart';

class FrequencyShifterDeviceSnapshot extends FrequencyFxDeviceSnapshot {
  const FrequencyShifterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.ffxShift,
    required this.ffxFine,
    required this.ffxMix,
    required this.ffxTone,
    required this.ffxFeedback,
  }) : super(type: 'frequency_shifter');

  final double ffxShift;
  final double ffxFine;
  final double ffxMix;
  final double ffxTone;
  final double ffxFeedback;

  factory FrequencyShifterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return FrequencyShifterDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      ffxShift: (params['ffxShift'] as num?)?.toDouble() ?? 0.5,
      ffxFine: (params['ffxFine'] as num?)?.toDouble() ?? 0.5,
      ffxMix: (params['ffxMix'] as num?)?.toDouble() ?? 1.0,
      ffxTone: (params['ffxTone'] as num?)?.toDouble() ?? 1.0,
      ffxFeedback: (params['ffxFeedback'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  FrequencyShifterDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? ffxShift,
    double? ffxFine,
    double? ffxMix,
    double? ffxTone,
    double? ffxFeedback,
  }) {
    return FrequencyShifterDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      ffxShift: ffxShift ?? this.ffxShift,
      ffxFine: ffxFine ?? this.ffxFine,
      ffxMix: ffxMix ?? this.ffxMix,
      ffxTone: ffxTone ?? this.ffxTone,
      ffxFeedback: ffxFeedback ?? this.ffxFeedback,
    );
  }

  @override
  FrequencyShifterDeviceSnapshot withParameter(
      String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'ffxShift' => copyWith(ffxShift: value.clamp(0.0, 1.0)),
      'ffxFine' => copyWith(ffxFine: value.clamp(0.0, 1.0)),
      'ffxMix' => copyWith(ffxMix: value.clamp(0.0, 1.0)),
      'ffxTone' => copyWith(ffxTone: value.clamp(0.0, 1.0)),
      'ffxFeedback' => copyWith(ffxFeedback: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
