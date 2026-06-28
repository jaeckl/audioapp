part of '../device_snapshot.dart';

class MidiDelayDeviceSnapshot extends DeviceSnapshot {
  const MidiDelayDeviceSnapshot({
    required super.id,
    required super.bypassed,
    required this.mode,
    required this.seconds,
    required this.division,
  }) : super(
          type: 'midi_delay',
          gain: 1,
          pan: 0.5,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
        );

  final double mode;
  final double seconds;
  final double division;
  bool get synced => mode >= 0.5;

  factory MidiDelayDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    return MidiDelayDeviceSnapshot(
      id: map['id'] as String? ?? '',
      bypassed: readBypass(map['bypass']),
      mode: (params['midiDelayMode'] as num?)?.toDouble() ?? 0,
      seconds: (params['midiDelaySeconds'] as num?)?.toDouble() ?? 0.25,
      division: (params['midiDelayDivision'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  MidiDelayDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? mode,
    double? seconds,
    double? division,
  }) => MidiDelayDeviceSnapshot(
        id: id ?? this.id,
        bypassed: bypassed ?? this.bypassed,
        mode: mode ?? this.mode,
        seconds: seconds ?? this.seconds,
        division: division ?? this.division,
      );

  @override
  MidiDelayDeviceSnapshot withParameter(String parameterId, double value) =>
      switch (parameterId) {
        'bypass' => copyWith(bypassed: value >= 0.5),
        'midiDelayMode' => copyWith(mode: value.clamp(0, 1)),
        'midiDelaySeconds' => copyWith(seconds: value.clamp(0, 2)),
        'midiDelayDivision' => copyWith(division: value.clamp(0.0625, 4)),
        _ => this,
      };
}
