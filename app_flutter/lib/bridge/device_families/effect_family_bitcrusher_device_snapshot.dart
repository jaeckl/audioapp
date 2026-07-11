part of '../device_snapshot.dart';

class BitcrusherDeviceSnapshot extends EffectDeviceSnapshot {
  const BitcrusherDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.bcRate,
    required this.bcBits,
    required this.bcMode,
    required this.bcShape,
    required this.bcJitter,
    required this.bcDrive,
    required this.bcDitherMode,
    required this.bcDitherAmount,
    required this.bcClipMode,
    required this.bcClipAmount,
    required this.bcFilter,
  }) : super(type: 'bitcrusher');

  final double bcRate;
  final double bcBits;
  final double bcMode, bcShape, bcJitter, bcDrive;
  final double bcDitherMode, bcDitherAmount, bcClipMode, bcClipAmount, bcFilter;

  factory BitcrusherDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return BitcrusherDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      bcRate: (params['rate'] as num?)?.toDouble() ?? 0.5,
      bcBits: (params['bits'] as num?)?.toDouble() ?? 8.0,
      bcMode: (params['mode'] as num?)?.toDouble() ?? 0.0,
      bcShape: (params['shape'] as num?)?.toDouble() ?? 0.0,
      bcJitter: (params['jitter'] as num?)?.toDouble() ?? 0.0,
      bcDrive: (params['drive'] as num?)?.toDouble() ?? 0.0,
      bcDitherMode: (params['ditherMode'] as num?)?.toDouble() ?? 0.0,
      bcDitherAmount: (params['ditherAmount'] as num?)?.toDouble() ?? 0.0,
      bcClipMode: (params['clipMode'] as num?)?.toDouble() ?? 0.0,
      bcClipAmount: (params['clipAmount'] as num?)?.toDouble() ?? 0.0,
      bcFilter: (params['filter'] as num?)?.toDouble() ?? 1.0,
      outputMix: (params['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (params['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  BitcrusherDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? bcRate,
    double? bcBits,
    double? bcMode,
    double? bcShape,
    double? bcJitter,
    double? bcDrive,
    double? bcDitherMode,
    double? bcDitherAmount,
    double? bcClipMode,
    double? bcClipAmount,
    double? bcFilter,
  }) {
    return BitcrusherDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      bcRate: bcRate ?? this.bcRate,
      bcBits: bcBits ?? this.bcBits,
      bcMode: bcMode ?? this.bcMode,
      bcShape: bcShape ?? this.bcShape,
      bcJitter: bcJitter ?? this.bcJitter,
      bcDrive: bcDrive ?? this.bcDrive,
      bcDitherMode: bcDitherMode ?? this.bcDitherMode,
      bcDitherAmount: bcDitherAmount ?? this.bcDitherAmount,
      bcClipMode: bcClipMode ?? this.bcClipMode,
      bcClipAmount: bcClipAmount ?? this.bcClipAmount,
      bcFilter: bcFilter ?? this.bcFilter,
    );
  }

  @override
  BitcrusherDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'rate' || 'bcRate' => copyWith(bcRate: value),
      'bits' || 'bcBits' => copyWith(bcBits: value),
      'mode' || 'bcMode' => copyWith(bcMode: value),
      'shape' || 'bcShape' => copyWith(bcShape: value),
      'jitter' || 'bcJitter' => copyWith(bcJitter: value),
      'drive' || 'bcDrive' => copyWith(bcDrive: value),
      'ditherMode' || 'bcDitherMode' => copyWith(bcDitherMode: value),
      'ditherAmount' || 'bcDitherAmount' => copyWith(bcDitherAmount: value),
      'clipMode' || 'bcClipMode' => copyWith(bcClipMode: value),
      'clipAmount' || 'bcClipAmount' => copyWith(bcClipAmount: value),
      'filter' || 'bcFilter' => copyWith(bcFilter: value),
      _ => this,
    };
  }
}
