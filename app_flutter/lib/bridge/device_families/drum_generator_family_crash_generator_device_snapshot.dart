part of '../device_snapshot.dart';

class CrashGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const CrashGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.crashModel,
    required this.crashColor,
    required this.crashSpread,
    required this.crashDecay,
    required this.crashVelocity,
    this.crashPitch = 0.50,
    this.crashKeyTrack = 0.0,
  }) : super(type: 'crash_generator');

  final double crashModel;
  final double crashColor;
  final double crashSpread;
  final double crashDecay;
  final double crashVelocity;
  final double crashPitch;
  final double crashKeyTrack;

  factory CrashGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return CrashGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      crashModel: (params['crashModel'] as num?)?.toDouble() ?? 0.0,
      crashColor: readCrashColor(params),
      crashSpread: (params['crashSpread'] as num?)?.toDouble() ?? 0.50,
      crashDecay: (params['crashDecay'] as num?)?.toDouble() ?? 0.55,
      crashVelocity: (params['crashVelocity'] as num?)?.toDouble() ?? 1.0,
      crashPitch: (params['crashPitch'] as num?)?.toDouble() ?? 0.50,
      crashKeyTrack: (params['crashKeyTrack'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  CrashGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? crashModel,
    double? crashColor,
    double? crashSpread,
    double? crashDecay,
    double? crashVelocity,
    double? crashPitch,
    double? crashKeyTrack,
  }) {
    return CrashGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      crashModel: crashModel ?? this.crashModel,
      crashColor: crashColor ?? this.crashColor,
      crashSpread: crashSpread ?? this.crashSpread,
      crashDecay: crashDecay ?? this.crashDecay,
      crashVelocity: crashVelocity ?? this.crashVelocity,
      crashPitch: crashPitch ?? this.crashPitch,
      crashKeyTrack: crashKeyTrack ?? this.crashKeyTrack,
    );
  }

  @override
  CrashGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'crashModel' => copyWith(crashModel: value.clamp(0.0, 1.0)),
      'crashColor' => copyWith(crashColor: value.clamp(0.0, 1.0)),
      'crashSpread' => copyWith(crashSpread: value.clamp(0.0, 1.0)),
      'crashDecay' => copyWith(crashDecay: value.clamp(0.0, 1.0)),
      'crashVelocity' => copyWith(crashVelocity: value.clamp(0.0, 1.0)),
      'crashPitch' => copyWith(crashPitch: value.clamp(0.0, 1.0)),
      'crashKeyTrack' => copyWith(crashKeyTrack: value >= 0.5 ? 1.0 : 0.0),
      _ => this,
    };
  }
}
