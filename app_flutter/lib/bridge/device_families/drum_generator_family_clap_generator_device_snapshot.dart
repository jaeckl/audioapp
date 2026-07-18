part of '../device_snapshot.dart';

class ClapGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const ClapGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.clapBursts,
    required this.clapSpread,
    required this.clapTone,
    required this.clapRoom,
    required this.clapDecay,
    required this.clapVelocity,
    this.clapPitch = 0.50,
    this.clapKeyTrack = 0.0,
  }) : super(type: 'clap_generator');

  final double clapBursts;
  final double clapSpread;
  final double clapTone;
  final double clapRoom;
  final double clapDecay;
  final double clapVelocity;
  final double clapPitch;
  final double clapKeyTrack;

  factory ClapGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ClapGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      clapBursts: (params['clapBursts'] as num?)?.toDouble() ?? 0.50,
      clapSpread: (params['clapSpread'] as num?)?.toDouble() ?? 0.45,
      clapTone: (params['clapTone'] as num?)?.toDouble() ?? 0.55,
      clapRoom: (params['clapRoom'] as num?)?.toDouble() ?? 0.50,
      clapDecay: (params['clapDecay'] as num?)?.toDouble() ?? 0.50,
      clapVelocity: (params['clapVelocity'] as num?)?.toDouble() ?? 1.0,
      clapPitch: (params['clapPitch'] as num?)?.toDouble() ?? 0.50,
      clapKeyTrack: (params['clapKeyTrack'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  ClapGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? clapBursts,
    double? clapSpread,
    double? clapTone,
    double? clapRoom,
    double? clapDecay,
    double? clapVelocity,
    double? clapPitch,
    double? clapKeyTrack,
  }) {
    return ClapGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      clapBursts: clapBursts ?? this.clapBursts,
      clapSpread: clapSpread ?? this.clapSpread,
      clapTone: clapTone ?? this.clapTone,
      clapRoom: clapRoom ?? this.clapRoom,
      clapDecay: clapDecay ?? this.clapDecay,
      clapVelocity: clapVelocity ?? this.clapVelocity,
      clapPitch: clapPitch ?? this.clapPitch,
      clapKeyTrack: clapKeyTrack ?? this.clapKeyTrack,
    );
  }

  @override
  ClapGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'clapBursts' => copyWith(clapBursts: value.clamp(0.0, 1.0)),
      'clapSpread' => copyWith(clapSpread: value.clamp(0.0, 1.0)),
      'clapTone' => copyWith(clapTone: value.clamp(0.0, 1.0)),
      'clapRoom' => copyWith(clapRoom: value.clamp(0.0, 1.0)),
      'clapDecay' => copyWith(clapDecay: value.clamp(0.0, 1.0)),
      'clapVelocity' => copyWith(clapVelocity: value.clamp(0.0, 1.0)),
      'clapPitch' => copyWith(clapPitch: value.clamp(0.0, 1.0)),
      'clapKeyTrack' => copyWith(clapKeyTrack: value >= 0.5 ? 1.0 : 0.0),
      _ => this,
    };
  }
}
