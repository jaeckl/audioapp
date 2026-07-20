part of '../device_snapshot.dart';

class UtilityDeviceSnapshot extends DeviceSnapshot {
  const UtilityDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.utilMono,
    required this.utilPolarity,
    required this.utilSwap,
    required this.utilTrim,
    required this.utilAutopan,
    required this.utilAutopanRate,
    required this.utilAutopanDepth,
  }) : super(type: 'utility');

  final double utilMono;
  final double utilPolarity;
  final double utilSwap;
  final double utilTrim;
  final double utilAutopan;
  final double utilAutopanRate;
  final double utilAutopanDepth;

  factory UtilityDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    return UtilityDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: 1.0,
      pan: 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: 0.0,
      meterInputLevel: 0.0,
      utilMono: (params['utilMono'] as num?)?.toDouble() ?? 0.0,
      utilPolarity: (params['utilPolarity'] as num?)?.toDouble() ?? 0.0,
      utilSwap: (params['utilSwap'] as num?)?.toDouble() ?? 0.0,
      utilTrim: (params['utilTrim'] as num?)?.toDouble() ?? 1.0,
      utilAutopan: (params['utilAutopan'] as num?)?.toDouble() ?? 0.0,
      utilAutopanRate: (params['utilAutopanRate'] as num?)?.toDouble() ?? 0.35,
      utilAutopanDepth:
          (params['utilAutopanDepth'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  UtilityDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? utilMono,
    double? utilPolarity,
    double? utilSwap,
    double? utilTrim,
    double? utilAutopan,
    double? utilAutopanRate,
    double? utilAutopanDepth,
  }) {
    return UtilityDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      utilMono: utilMono ?? this.utilMono,
      utilPolarity: utilPolarity ?? this.utilPolarity,
      utilSwap: utilSwap ?? this.utilSwap,
      utilTrim: utilTrim ?? this.utilTrim,
      utilAutopan: utilAutopan ?? this.utilAutopan,
      utilAutopanRate: utilAutopanRate ?? this.utilAutopanRate,
      utilAutopanDepth: utilAutopanDepth ?? this.utilAutopanDepth,
    );
  }

  @override
  UtilityDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'bypass' => copyWith(bypassed: value >= 0.5),
      'utilMono' => copyWith(utilMono: value.clamp(0.0, 1.0)),
      'utilPolarity' => copyWith(utilPolarity: value.clamp(0.0, 1.0)),
      'utilSwap' => copyWith(utilSwap: value.clamp(0.0, 1.0)),
      'utilTrim' => copyWith(utilTrim: value.clamp(0.0, 1.0)),
      'utilAutopan' => copyWith(utilAutopan: value.clamp(0.0, 1.0)),
      'utilAutopanRate' => copyWith(utilAutopanRate: value.clamp(0.0, 1.0)),
      'utilAutopanDepth' => copyWith(utilAutopanDepth: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
