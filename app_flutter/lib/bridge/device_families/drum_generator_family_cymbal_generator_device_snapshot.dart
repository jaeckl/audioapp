part of '../device_snapshot.dart';

class CymbalGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const CymbalGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.cymbalModel,
    required this.cymbalColor,
    required this.cymbalDecay,
    required this.cymbalVelocity,
    required this.cymbalWidth,
  }) : super(type: 'cymbal_generator');

  final double cymbalModel;
  final double cymbalColor;
  final double cymbalDecay;
  final double cymbalVelocity;
  final double cymbalWidth;

  factory CymbalGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return CymbalGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      cymbalModel: (params['cymbalModel'] as num?)?.toDouble() ?? 0.0,
      cymbalColor: readCymbalColor(params),
      cymbalDecay: (params['cymbalDecay'] as num?)?.toDouble() ?? 0.50,
      cymbalVelocity: (params['cymbalVelocity'] as num?)?.toDouble() ?? 1.0,
      cymbalWidth: (params['cymbalWidth'] as num?)?.toDouble() ?? 0.35,
    );
  }

  @override
  CymbalGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? cymbalModel,
    double? cymbalColor,
    double? cymbalDecay,
    double? cymbalVelocity,
    double? cymbalWidth,
  }) {
    return CymbalGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      cymbalModel: cymbalModel ?? this.cymbalModel,
      cymbalColor: cymbalColor ?? this.cymbalColor,
      cymbalDecay: cymbalDecay ?? this.cymbalDecay,
      cymbalVelocity: cymbalVelocity ?? this.cymbalVelocity,
      cymbalWidth: cymbalWidth ?? this.cymbalWidth,
    );
  }

  @override
  CymbalGeneratorDeviceSnapshot withParameter(
      String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'cymbalModel' => copyWith(cymbalModel: value.clamp(0.0, 1.0)),
      'cymbalColor' => copyWith(cymbalColor: value.clamp(0.0, 1.0)),
      'cymbalDecay' => copyWith(cymbalDecay: value.clamp(0.0, 1.0)),
      'cymbalVelocity' => copyWith(cymbalVelocity: value.clamp(0.0, 1.0)),
      'cymbalWidth' => copyWith(cymbalWidth: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
