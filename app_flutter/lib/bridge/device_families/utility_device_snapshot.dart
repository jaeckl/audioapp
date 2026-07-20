part of '../device_snapshot.dart';

class UtilityDeviceSnapshot extends DeviceSnapshot {
  const UtilityDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.utilWidth,
    required this.utilInvertL,
    required this.utilInvertR,
    required this.utilSwap,
    required this.utilTrim,
    required this.utilAutopan,
    required this.utilAutopanRate,
    required this.utilAutopanDepth,
  }) : super(type: 'utility');

  /// 0 = mono, 1 = full stereo.
  final double utilWidth;
  final double utilInvertL;
  final double utilInvertR;
  final double utilSwap;
  final double utilTrim;
  final double utilAutopan;
  final double utilAutopanRate;
  final double utilAutopanDepth;

  static (double, double) _invertFromLegacyPolarity(double pol) {
    if (pol >= 0.83) return (1.0, 1.0);
    if (pol >= 0.5) return (0.0, 1.0);
    if (pol >= 0.16) return (1.0, 0.0);
    return (0.0, 0.0);
  }

  factory UtilityDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    double width;
    if (params['utilWidth'] is num) {
      width = (params['utilWidth'] as num).toDouble();
    } else if (params['utilMono'] is num) {
      width = (params['utilMono'] as num).toDouble() >= 0.5 ? 0.0 : 1.0;
    } else {
      width = 1.0;
    }
    late final double invertL;
    late final double invertR;
    if (params['utilInvertL'] is num || params['utilInvertR'] is num) {
      invertL = ((params['utilInvertL'] as num?)?.toDouble() ?? 0.0) >= 0.5
          ? 1.0
          : 0.0;
      invertR = ((params['utilInvertR'] as num?)?.toDouble() ?? 0.0) >= 0.5
          ? 1.0
          : 0.0;
    } else if (params['utilPolarity'] is num) {
      final pair =
          _invertFromLegacyPolarity((params['utilPolarity'] as num).toDouble());
      invertL = pair.$1;
      invertR = pair.$2;
    } else {
      invertL = 0.0;
      invertR = 0.0;
    }
    return UtilityDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: 1.0,
      pan: 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: 0.0,
      meterInputLevel: 0.0,
      utilWidth: width,
      utilInvertL: invertL,
      utilInvertR: invertR,
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
    double? utilWidth,
    double? utilInvertL,
    double? utilInvertR,
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
      utilWidth: utilWidth ?? this.utilWidth,
      utilInvertL: utilInvertL ?? this.utilInvertL,
      utilInvertR: utilInvertR ?? this.utilInvertR,
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
      'utilWidth' || 'utilMono' => copyWith(utilWidth: value.clamp(0.0, 1.0)),
      'utilInvertL' => copyWith(utilInvertL: value >= 0.5 ? 1.0 : 0.0),
      'utilInvertR' => copyWith(utilInvertR: value >= 0.5 ? 1.0 : 0.0),
      'utilSwap' => copyWith(utilSwap: value >= 0.5 ? 1.0 : 0.0),
      'utilTrim' => copyWith(utilTrim: value.clamp(0.0, 1.0)),
      'utilAutopan' => copyWith(utilAutopan: value >= 0.5 ? 1.0 : 0.0),
      'utilAutopanRate' => copyWith(utilAutopanRate: value.clamp(0.0, 1.0)),
      'utilAutopanDepth' => copyWith(utilAutopanDepth: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
