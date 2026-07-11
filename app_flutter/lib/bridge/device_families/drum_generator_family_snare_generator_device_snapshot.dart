part of '../device_snapshot.dart';

class SnareGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const SnareGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.snareModel,
    required this.snareBody,
    required this.snareRing,
    required this.snareTune,
    required this.snareSnares,
    required this.snareSnap,
    required this.snareDecay,
    required this.snareVelocity,
  }) : super(type: 'snare_generator');

  final double snareModel;
  final double snareBody;
  final double snareRing;
  final double snareTune;
  final double snareSnares;
  final double snareSnap;
  final double snareDecay;
  final double snareVelocity;

  factory SnareGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return SnareGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      snareModel: (params['snareModel'] as num?)?.toDouble() ?? 0.0,
      snareBody: (params['snareBody'] as num?)?.toDouble() ?? 0.45,
      snareRing: (params['snareRing'] as num?)?.toDouble() ?? 0.40,
      snareTune: (params['snareTune'] as num?)?.toDouble() ?? 0.50,
      snareSnares: (params['snareSnares'] as num?)?.toDouble() ?? 0.60,
      snareSnap: (params['snareSnap'] as num?)?.toDouble() ?? 0.40,
      snareDecay: (params['snareDecay'] as num?)?.toDouble() ?? 0.50,
      snareVelocity: (params['snareVelocity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  SnareGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? snareModel,
    double? snareBody,
    double? snareRing,
    double? snareTune,
    double? snareSnares,
    double? snareSnap,
    double? snareDecay,
    double? snareVelocity,
  }) {
    return SnareGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      snareModel: snareModel ?? this.snareModel,
      snareBody: snareBody ?? this.snareBody,
      snareRing: snareRing ?? this.snareRing,
      snareTune: snareTune ?? this.snareTune,
      snareSnares: snareSnares ?? this.snareSnares,
      snareSnap: snareSnap ?? this.snareSnap,
      snareDecay: snareDecay ?? this.snareDecay,
      snareVelocity: snareVelocity ?? this.snareVelocity,
    );
  }

  @override
  SnareGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'snareModel' => copyWith(snareModel: value.clamp(0.0, 1.0)),
      'snareBody' => copyWith(snareBody: value.clamp(0.0, 1.0)),
      'snareRing' => copyWith(snareRing: value.clamp(0.0, 1.0)),
      'snareTune' => copyWith(snareTune: value.clamp(0.0, 1.0)),
      'snareSnares' => copyWith(snareSnares: value.clamp(0.0, 1.0)),
      'snareSnap' => copyWith(snareSnap: value.clamp(0.0, 1.0)),
      'snareDecay' => copyWith(snareDecay: value.clamp(0.0, 1.0)),
      'snareVelocity' => copyWith(snareVelocity: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
