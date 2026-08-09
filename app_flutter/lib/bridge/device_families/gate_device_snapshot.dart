part of '../device_snapshot.dart';

class GateDeviceSnapshot extends DynamicsDeviceSnapshot {
  const GateDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.gateThreshold,
    required this.gateAttack,
    required this.gateRelease,
    required this.gateHold,
    required this.gateRange,
  }) : super(type: 'gate');

  final double gateThreshold;
  final double gateAttack;
  final double gateRelease;
  final double gateHold;
  final double gateRange;

  factory GateDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return GateDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      gateThreshold: (params['gateThreshold'] as num?)?.toDouble() ?? 0.28,
      gateAttack: (params['gateAttack'] as num?)?.toDouble() ?? 0.25,
      gateRelease: (params['gateRelease'] as num?)?.toDouble() ?? 0.50,
      gateHold: (params['gateHold'] as num?)?.toDouble() ?? 0.20,
      gateRange: (params['gateRange'] as num?)?.toDouble() ?? 0.30,
    );
  }

  @override
  GateDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? gateThreshold,
    double? gateAttack,
    double? gateRelease,
    double? gateHold,
    double? gateRange,
  }) {
    return GateDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      gateThreshold: gateThreshold ?? this.gateThreshold,
      gateAttack: gateAttack ?? this.gateAttack,
      gateRelease: gateRelease ?? this.gateRelease,
      gateHold: gateHold ?? this.gateHold,
      gateRange: gateRange ?? this.gateRange,
    );
  }

  @override
  GateDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'gateThreshold' => copyWith(gateThreshold: value.clamp(0.0, 1.0)),
      'gateAttack' => copyWith(gateAttack: value.clamp(0.0, 1.0)),
      'gateRelease' => copyWith(gateRelease: value.clamp(0.0, 1.0)),
      'gateHold' => copyWith(gateHold: value.clamp(0.0, 1.0)),
      'gateRange' => copyWith(gateRange: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
