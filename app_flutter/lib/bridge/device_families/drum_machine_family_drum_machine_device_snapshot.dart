part of '../device_snapshot.dart';

class DrumMachineDeviceSnapshot extends DeviceSnapshot {
  const DrumMachineDeviceSnapshot({
    required super.id,
    required super.bypassed,
    this.pads = const [],
  }) : super(
          type: 'drum_machine',
          gain: 1,
          pan: 0.5,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
        );

  final List<DrumPadSnapshot> pads;

  DrumPadSnapshot padForNote(int note) => pads.firstWhere(
        (pad) => pad.note == note,
        orElse: () => DrumPadSnapshot(note: note),
      );

  factory DrumMachineDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) =>
      DrumMachineDeviceSnapshot(
        id: map['id'] as String? ?? '',
        bypassed: readBypass(map['bypass']),
        pads: (map['pads'] as List<dynamic>? ?? const [])
            .map((value) =>
                DrumPadSnapshot.fromMap(value as Map<dynamic, dynamic>))
            .toList(growable: false),
      );

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
        pads: pads ?? this.pads,
      );

  @override
  DrumMachineDeviceSnapshot withParameter(String parameterId, double value) =>
      parameterId == 'bypass' ? copyWith(bypassed: value >= 0.5) : this;
}
