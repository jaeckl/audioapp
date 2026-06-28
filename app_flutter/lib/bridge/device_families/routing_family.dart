part of '../device_snapshot.dart';

class RoutingDeviceSnapshot extends DeviceSnapshot {
  const RoutingDeviceSnapshot({
    required super.id,
    required super.type,
    required super.bypassed,
    required this.sourceId,
    required this.routeMix,
  }) : super(
          gain: 1,
          pan: 0.5,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
        );

  final String sourceId;
  final double routeMix;

  bool get isAudioRoute => type == 'audio_receiver';

  factory RoutingDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    return RoutingDeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'audio_receiver',
      bypassed: readBypass(map['bypass']),
      sourceId: params['sourceId'] as String? ?? '',
      routeMix: (params['routeMix'] as num?)?.toDouble() ?? 1,
    );
  }

  @override
  RoutingDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    String? sourceId,
    double? routeMix,
  }) =>
      RoutingDeviceSnapshot(
        id: id ?? this.id,
        type: type ?? this.type,
        bypassed: bypassed ?? this.bypassed,
        sourceId: sourceId ?? this.sourceId,
        routeMix: routeMix ?? this.routeMix,
      );

  @override
  RoutingDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'bypass' => copyWith(bypassed: value >= 0.5),
      'routeMix' => copyWith(routeMix: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }

  RoutingDeviceSnapshot withSourceId(String value) => copyWith(sourceId: value);
}
