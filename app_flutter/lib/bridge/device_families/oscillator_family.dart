part of '../device_snapshot.dart';

/// Simple oscillator device snapshot.
class OscillatorDeviceSnapshot extends DeviceSnapshot {
  const OscillatorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.frequencyHz,
  }) : super(type: 'simple_oscillator');

  final double frequencyHz;

  factory OscillatorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return OscillatorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      frequencyHz: (params['frequency'] as num?)?.toDouble() ?? 440.0,
    );
  }

  @override
  OscillatorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? frequencyHz,
  }) {
    return OscillatorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      frequencyHz: frequencyHz ?? this.frequencyHz,
    );
  }

  @override
  OscillatorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'frequency' => copyWith(frequencyHz: value),
      _ => this,
    };
  }
}