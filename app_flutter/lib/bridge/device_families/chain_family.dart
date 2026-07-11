part of '../device_snapshot.dart';

class ChainDeviceSnapshot extends DeviceSnapshot {
  const ChainDeviceSnapshot({
    required super.id,
    required super.bypassed,
    this.mix = 1,
    this.chainGain = 1,
    this.devices = const [],
  }) : super(
            type: 'device_chain',
            gain: 1,
            pan: 0.5,
            meterGainReductionDb: 0,
            meterInputLevel: 0);

  final double mix;
  final double chainGain;
  final List<DeviceSnapshot> devices;

  factory ChainDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final p = map['parameters'] as Map<dynamic, dynamic>? ?? const {};
    return ChainDeviceSnapshot(
      id: map['id'] as String? ?? '',
      bypassed: readBypass(map['bypass']),
      mix: (p['chainMix'] as num?)?.toDouble() ?? 1,
      chainGain: (p['chainGain'] as num?)?.toDouble() ?? 1,
      devices: parseDeviceList(map, 'devices'),
    );
  }

  @override
  ChainDeviceSnapshot withParameter(String id, double value) => switch (id) {
        'chainMix' => copyWith(mix: value),
        'chainGain' => copyWith(chainGain: value),
        'bypass' => copyWith(bypassed: value >= 0.5),
        _ => this,
      };

  @override
  ChainDeviceSnapshot copyWith(
          {String? id,
          String? type,
          double? gain,
          double? pan,
          bool? bypassed,
          double? meterGainReductionDb,
          double? meterInputLevel,
          double? mix,
          double? chainGain,
          List<DeviceSnapshot>? devices}) =>
      ChainDeviceSnapshot(
          id: id ?? this.id,
          bypassed: bypassed ?? this.bypassed,
          mix: mix ?? this.mix,
          chainGain: chainGain ?? this.chainGain,
          devices: devices ?? this.devices);
}
