part of '../device_snapshot.dart';

class ExpanderDeviceSnapshot extends DynamicsDeviceSnapshot {
  const ExpanderDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.expandThreshold,
    required this.expandRatio,
    required this.expandAttack,
    required this.expandRelease,
    required this.expandRange,
  }) : super(type: 'expander');

  final double expandThreshold;
  final double expandRatio;
  final double expandAttack;
  final double expandRelease;
  final double expandRange;

  factory ExpanderDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ExpanderDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      expandThreshold: (params['expandThreshold'] as num?)?.toDouble() ?? 0.40,
      expandRatio: (params['expandRatio'] as num?)?.toDouble() ?? 0.45,
      expandAttack: (params['expandAttack'] as num?)?.toDouble() ?? 0.25,
      expandRelease: (params['expandRelease'] as num?)?.toDouble() ?? 0.55,
      expandRange: (params['expandRange'] as num?)?.toDouble() ?? 0.15,
    );
  }

  @override
  ExpanderDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? expandThreshold,
    double? expandRatio,
    double? expandAttack,
    double? expandRelease,
    double? expandRange,
  }) {
    return ExpanderDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      expandThreshold: expandThreshold ?? this.expandThreshold,
      expandRatio: expandRatio ?? this.expandRatio,
      expandAttack: expandAttack ?? this.expandAttack,
      expandRelease: expandRelease ?? this.expandRelease,
      expandRange: expandRange ?? this.expandRange,
    );
  }

  @override
  ExpanderDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'expandThreshold' => copyWith(expandThreshold: value.clamp(0.0, 1.0)),
      'expandRatio' => copyWith(expandRatio: value.clamp(0.0, 1.0)),
      'expandAttack' => copyWith(expandAttack: value.clamp(0.0, 1.0)),
      'expandRelease' => copyWith(expandRelease: value.clamp(0.0, 1.0)),
      'expandRange' => copyWith(expandRange: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
