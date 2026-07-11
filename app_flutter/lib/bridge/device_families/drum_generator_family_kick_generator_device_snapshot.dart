part of '../device_snapshot.dart';

class KickGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const KickGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.kickModel,
    required this.kickPitch,
    required this.kickPunch,
    required this.kickDecay,
    required this.kickClick,
    required this.kickTone,
    required this.kickVelocity,
    required this.kickKeyTrack,
  }) : super(type: 'kick_generator');

  final double kickModel;
  final double kickPitch;
  final double kickPunch;
  final double kickDecay;
  final double kickClick;
  final double kickTone;
  final double kickVelocity;
  final double kickKeyTrack;

  factory KickGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return KickGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      kickModel: (params['kickModel'] as num?)?.toDouble() ?? 0.0,
      kickPitch: (params['kickPitch'] as num?)?.toDouble() ?? 0.55,
      kickPunch: (params['kickPunch'] as num?)?.toDouble() ?? 0.60,
      kickDecay: (params['kickDecay'] as num?)?.toDouble() ?? 0.50,
      kickClick: (params['kickClick'] as num?)?.toDouble() ?? 0.35,
      kickTone: (params['kickTone'] as num?)?.toDouble() ?? 0.50,
      kickVelocity: (params['kickVelocity'] as num?)?.toDouble() ?? 1.0,
      kickKeyTrack: (params['kickKeyTrack'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  KickGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? kickModel,
    double? kickPitch,
    double? kickPunch,
    double? kickDecay,
    double? kickClick,
    double? kickTone,
    double? kickVelocity,
    double? kickKeyTrack,
  }) {
    return KickGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      kickModel: kickModel ?? this.kickModel,
      kickPitch: kickPitch ?? this.kickPitch,
      kickPunch: kickPunch ?? this.kickPunch,
      kickDecay: kickDecay ?? this.kickDecay,
      kickClick: kickClick ?? this.kickClick,
      kickTone: kickTone ?? this.kickTone,
      kickVelocity: kickVelocity ?? this.kickVelocity,
      kickKeyTrack: kickKeyTrack ?? this.kickKeyTrack,
    );
  }

  @override
  KickGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'kickModel' => copyWith(kickModel: value.clamp(0.0, 1.0)),
      'kickPitch' => copyWith(kickPitch: value.clamp(0.0, 1.0)),
      'kickPunch' => copyWith(kickPunch: value.clamp(0.0, 1.0)),
      'kickDecay' => copyWith(kickDecay: value.clamp(0.0, 1.0)),
      'kickClick' => copyWith(kickClick: value.clamp(0.0, 1.0)),
      'kickTone' => copyWith(kickTone: value.clamp(0.0, 1.0)),
      'kickVelocity' => copyWith(kickVelocity: value.clamp(0.0, 1.0)),
      'kickKeyTrack' => copyWith(kickKeyTrack: value >= 0.5 ? 1.0 : 0.0),
      _ => this,
    };
  }
}
