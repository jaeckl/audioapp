part of '../device_snapshot.dart';

final class DedicatedPercussionDeviceSnapshot
    extends DrumGeneratorDeviceSnapshot {
  const DedicatedPercussionDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.parameters,
  });

  final Map<String, double> parameters;

  factory DedicatedPercussionDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final raw = map['parameters'] as Map<dynamic, dynamic>? ?? const {};
    final output = map['outputPanel'] as Map<dynamic, dynamic>? ?? const {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? const {};
    return DedicatedPercussionDeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'hihat_generator',
      gain: (output['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (output['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      parameters: {
        for (final entry in raw.entries)
          if (entry.value is num)
            entry.key.toString(): (entry.value as num).toDouble(),
      },
    );
  }

  double value(String parameterId, [double fallback = 0.5]) =>
      parameters[parameterId] ?? fallback;

  @override
  DedicatedPercussionDeviceSnapshot withParameter(
      String parameterId, double value) {
    if (parameterId == 'gain') return copyWith(gain: value);
    if (parameterId == 'pan') return copyWith(pan: value);
    if (parameterId == 'bypass') return copyWith(bypassed: value >= 0.5);
    return copyWith(parameters: {
      ...parameters,
      parameterId: parameterId.endsWith('KeyTrack')
          ? (value >= 0.5 ? 1.0 : 0.0)
          : value.clamp(0.0, 1.0),
    });
  }

  @override
  DedicatedPercussionDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    Map<String, double>? parameters,
  }) =>
      DedicatedPercussionDeviceSnapshot(
        id: id ?? this.id,
        type: type ?? this.type,
        gain: gain ?? this.gain,
        pan: pan ?? this.pan,
        bypassed: bypassed ?? this.bypassed,
        meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
        meterInputLevel: meterInputLevel ?? this.meterInputLevel,
        parameters: parameters ?? this.parameters,
      );
}
