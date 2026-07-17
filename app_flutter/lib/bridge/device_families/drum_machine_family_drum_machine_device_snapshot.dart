part of '../device_snapshot.dart';

class DrumMachineDeviceSnapshot extends DeviceSnapshot {
  const DrumMachineDeviceSnapshot({
    required super.id,
    required super.bypassed,
    double gain = 1,
    double pan = 0.5,
    this.pads = const [],
  }) : super(
          type: 'drum_machine',
          gain: gain,
          pan: pan,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
        );

  final List<DrumPadSnapshot> pads;

  DrumPadSnapshot padForNote(int note) => pads.firstWhere(
        (pad) => pad.note == note,
        orElse: () => DrumPadSnapshot(note: note),
      );

  factory DrumMachineDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    return DrumMachineDeviceSnapshot(
      id: map['id'] as String? ?? '',
      bypassed: readBypass(map['bypass']),
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      pads: (map['pads'] as List<dynamic>? ?? const [])
          .map((value) =>
              DrumPadSnapshot.fromMap(value as Map<dynamic, dynamic>))
          .toList(growable: false),
    );
  }

  @override
  DrumMachineDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    List<DrumPadSnapshot>? pads,
  }) =>
      DrumMachineDeviceSnapshot(
        id: id ?? this.id,
        bypassed: bypassed ?? this.bypassed,
        gain: gain ?? this.gain,
        pan: pan ?? this.pan,
        pads: pads ?? this.pads,
      );

  @override
  DrumMachineDeviceSnapshot withParameter(String parameterId, double value) =>
      switch (parameterId) {
        'gain' => copyWith(gain: value),
        'pan' => copyWith(pan: value),
        'bypass' => copyWith(bypassed: value >= 0.5),
        _ => this,
      };
}
