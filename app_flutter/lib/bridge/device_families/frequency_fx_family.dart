part of '../device_snapshot.dart';

sealed class FrequencyFxDeviceSnapshot extends DeviceSnapshot {
  const FrequencyFxDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  });
}

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
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
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

class FourBandEqDeviceSnapshot extends FrequencyFxDeviceSnapshot {
  const FourBandEqDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.ffxBand1Freq,
    required this.ffxBand1Gain,
    required this.ffxBand1Q,
    required this.ffxBand2Freq,
    required this.ffxBand2Gain,
    required this.ffxBand2Q,
    required this.ffxBand3Freq,
    required this.ffxBand3Gain,
    required this.ffxBand3Q,
    required this.ffxBand4Freq,
    required this.ffxBand4Gain,
    required this.ffxBand4Q,
  }) : super(type: 'four_band_eq');

  final double ffxBand1Freq;
  final double ffxBand1Gain;
  final double ffxBand1Q;
  final double ffxBand2Freq;
  final double ffxBand2Gain;
  final double ffxBand2Q;
  final double ffxBand3Freq;
  final double ffxBand3Gain;
  final double ffxBand3Q;
  final double ffxBand4Freq;
  final double ffxBand4Gain;
  final double ffxBand4Q;

  factory FourBandEqDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return FourBandEqDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      ffxBand1Freq: (params['ffxBand1Freq'] as num?)?.toDouble() ?? 0.15,
      ffxBand1Gain: (params['ffxBand1Gain'] as num?)?.toDouble() ?? 0.5,
      ffxBand1Q: (params['ffxBand1Q'] as num?)?.toDouble() ?? 0.5,
      ffxBand2Freq: (params['ffxBand2Freq'] as num?)?.toDouble() ?? 0.35,
      ffxBand2Gain: (params['ffxBand2Gain'] as num?)?.toDouble() ?? 0.5,
      ffxBand2Q: (params['ffxBand2Q'] as num?)?.toDouble() ?? 0.5,
      ffxBand3Freq: (params['ffxBand3Freq'] as num?)?.toDouble() ?? 0.6,
      ffxBand3Gain: (params['ffxBand3Gain'] as num?)?.toDouble() ?? 0.5,
      ffxBand3Q: (params['ffxBand3Q'] as num?)?.toDouble() ?? 0.5,
      ffxBand4Freq: (params['ffxBand4Freq'] as num?)?.toDouble() ?? 0.85,
      ffxBand4Gain: (params['ffxBand4Gain'] as num?)?.toDouble() ?? 0.5,
      ffxBand4Q: (params['ffxBand4Q'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  FourBandEqDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? ffxBand1Freq,
    double? ffxBand1Gain,
    double? ffxBand1Q,
    double? ffxBand2Freq,
    double? ffxBand2Gain,
    double? ffxBand2Q,
    double? ffxBand3Freq,
    double? ffxBand3Gain,
    double? ffxBand3Q,
    double? ffxBand4Freq,
    double? ffxBand4Gain,
    double? ffxBand4Q,
  }) {
    return FourBandEqDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      ffxBand1Freq: ffxBand1Freq ?? this.ffxBand1Freq,
      ffxBand1Gain: ffxBand1Gain ?? this.ffxBand1Gain,
      ffxBand1Q: ffxBand1Q ?? this.ffxBand1Q,
      ffxBand2Freq: ffxBand2Freq ?? this.ffxBand2Freq,
      ffxBand2Gain: ffxBand2Gain ?? this.ffxBand2Gain,
      ffxBand2Q: ffxBand2Q ?? this.ffxBand2Q,
      ffxBand3Freq: ffxBand3Freq ?? this.ffxBand3Freq,
      ffxBand3Gain: ffxBand3Gain ?? this.ffxBand3Gain,
      ffxBand3Q: ffxBand3Q ?? this.ffxBand3Q,
      ffxBand4Freq: ffxBand4Freq ?? this.ffxBand4Freq,
      ffxBand4Gain: ffxBand4Gain ?? this.ffxBand4Gain,
      ffxBand4Q: ffxBand4Q ?? this.ffxBand4Q,
    );
  }

  @override
  FourBandEqDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'ffxBand1Freq' => copyWith(ffxBand1Freq: value.clamp(0.0, 1.0)),
      'ffxBand1Gain' => copyWith(ffxBand1Gain: value.clamp(0.0, 1.0)),
      'ffxBand1Q' => copyWith(ffxBand1Q: value.clamp(0.0, 1.0)),
      'ffxBand2Freq' => copyWith(ffxBand2Freq: value.clamp(0.0, 1.0)),
      'ffxBand2Gain' => copyWith(ffxBand2Gain: value.clamp(0.0, 1.0)),
      'ffxBand2Q' => copyWith(ffxBand2Q: value.clamp(0.0, 1.0)),
      'ffxBand3Freq' => copyWith(ffxBand3Freq: value.clamp(0.0, 1.0)),
      'ffxBand3Gain' => copyWith(ffxBand3Gain: value.clamp(0.0, 1.0)),
      'ffxBand3Q' => copyWith(ffxBand3Q: value.clamp(0.0, 1.0)),
      'ffxBand4Freq' => copyWith(ffxBand4Freq: value.clamp(0.0, 1.0)),
      'ffxBand4Gain' => copyWith(ffxBand4Gain: value.clamp(0.0, 1.0)),
      'ffxBand4Q' => copyWith(ffxBand4Q: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class FrequencyShifterDeviceSnapshot extends FrequencyFxDeviceSnapshot {
  const FrequencyShifterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.ffxShift,
  }) : super(type: 'frequency_shifter');

  final double ffxShift;

  factory FrequencyShifterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return FrequencyShifterDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      ffxShift: (params['ffxShift'] as num?)?.toDouble() ?? 0.5,
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
  }) {
    return FrequencyShifterDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      ffxShift: ffxShift ?? this.ffxShift,
    );
  }

  @override
  FrequencyShifterDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'ffxShift' => copyWith(ffxShift: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}