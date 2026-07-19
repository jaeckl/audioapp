part of '../device_snapshot.dart';

class DcOffsetDeviceSnapshot extends EffectDeviceSnapshot {
  const DcOffsetDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.dcMode,
    required this.dcAmount,
    required this.dcCutoff,
  }) : super(type: 'dc_offset');

  /// 0 = Mean, 1 = HPF
  final double dcMode;
  final double dcAmount;
  final double dcCutoff;

  factory DcOffsetDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DcOffsetDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      dcMode: (params['mode'] as num?)?.toDouble() ?? 1.0,
      dcAmount: (params['amount'] as num?)?.toDouble() ?? 1.0,
      dcCutoff: (params['cutoff'] as num?)?.toDouble() ?? 0.3,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (params['outputMix'] as num?)?.toDouble() ??
          1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (params['outputWidth'] as num?)?.toDouble() ??
          1.0,
    );
  }

  @override
  DcOffsetDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? dcMode,
    double? dcAmount,
    double? dcCutoff,
  }) {
    return DcOffsetDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      dcMode: dcMode ?? this.dcMode,
      dcAmount: dcAmount ?? this.dcAmount,
      dcCutoff: dcCutoff ?? this.dcCutoff,
    );
  }

  @override
  DcOffsetDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'mode' || 'dcMode' => copyWith(dcMode: value),
      'amount' || 'dcAmount' => copyWith(dcAmount: value),
      'cutoff' || 'dcCutoff' => copyWith(dcCutoff: value),
      _ => this,
    };
  }
}
