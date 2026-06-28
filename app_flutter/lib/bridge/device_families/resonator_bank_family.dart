part of '../device_snapshot.dart';

class ResonatorBankDeviceSnapshot extends DeviceSnapshot {
  const ResonatorBankDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.resRoot,
    required this.resSpread,
    required this.resDecay,
    required this.resDamping,
    required this.resColor,
    required this.resWidth,
    required this.resMix,
  }) : super(type: 'resonator_bank');

  final double resRoot;
  final double resSpread;
  final double resDecay;
  final double resDamping;
  final double resColor;
  final double resWidth;
  final double resMix;

  factory ResonatorBankDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final output = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ResonatorBankDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (output['gain'] as num?)?.toDouble() ?? 1,
      pan: (output['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0,
      resRoot: (params['resRoot'] as num?)?.toDouble() ?? 0.5,
      resSpread: (params['resSpread'] as num?)?.toDouble() ?? 0.5,
      resDecay: (params['resDecay'] as num?)?.toDouble() ?? 0.55,
      resDamping: (params['resDamping'] as num?)?.toDouble() ?? 0.35,
      resColor: (params['resColor'] as num?)?.toDouble() ?? 0.5,
      resWidth: (params['resWidth'] as num?)?.toDouble() ?? 0.5,
      resMix: (params['resMix'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  ResonatorBankDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? resRoot,
    double? resSpread,
    double? resDecay,
    double? resDamping,
    double? resColor,
    double? resWidth,
    double? resMix,
  }) =>
      ResonatorBankDeviceSnapshot(
        id: id ?? this.id,
        gain: gain ?? this.gain,
        pan: pan ?? this.pan,
        bypassed: bypassed ?? this.bypassed,
        meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
        meterInputLevel: meterInputLevel ?? this.meterInputLevel,
        resRoot: resRoot ?? this.resRoot,
        resSpread: resSpread ?? this.resSpread,
        resDecay: resDecay ?? this.resDecay,
        resDamping: resDamping ?? this.resDamping,
        resColor: resColor ?? this.resColor,
        resWidth: resWidth ?? this.resWidth,
        resMix: resMix ?? this.resMix,
      );

  @override
  ResonatorBankDeviceSnapshot withParameter(String parameterId, double value) {
    final v = value.clamp(0.0, 1.0);
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'resRoot' => copyWith(resRoot: v),
      'resSpread' => copyWith(resSpread: v),
      'resDecay' => copyWith(resDecay: v),
      'resDamping' => copyWith(resDamping: v),
      'resColor' => copyWith(resColor: v),
      'resWidth' => copyWith(resWidth: v),
      'resMix' => copyWith(resMix: v),
      _ => this,
    };
  }
}
