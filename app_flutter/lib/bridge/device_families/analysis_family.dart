part of '../device_snapshot.dart';

class AnalysisDeviceSnapshot extends DeviceSnapshot {
  const AnalysisDeviceSnapshot(
      {required super.id,
      required super.type,
      required super.gain,
      required super.pan,
      required super.bypassed,
      required super.meterGainReductionDb,
      required super.meterInputLevel});

  factory AnalysisDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? const {};
    return AnalysisDeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      gain: 1,
      pan: 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0,
    );
  }
  @override
  AnalysisDeviceSnapshot withParameter(String id, double value) =>
      id == 'bypass' ? copyWith(bypassed: value >= .5) : this;
  @override
  AnalysisDeviceSnapshot copyWith(
          {String? id,
          String? type,
          double? gain,
          double? pan,
          bool? bypassed,
          double? meterGainReductionDb,
          double? meterInputLevel}) =>
      AnalysisDeviceSnapshot(
          id: id ?? this.id,
          type: type ?? this.type,
          gain: gain ?? this.gain,
          pan: pan ?? this.pan,
          bypassed: bypassed ?? this.bypassed,
          meterGainReductionDb:
              meterGainReductionDb ?? this.meterGainReductionDb,
          meterInputLevel: meterInputLevel ?? this.meterInputLevel);
}
