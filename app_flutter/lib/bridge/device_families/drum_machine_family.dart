part of '../device_snapshot.dart';

class DrumPadSnapshot {
  const DrumPadSnapshot({
    required this.note,
    this.name = '',
    this.gain = 1,
    this.pan = 0.5,
    this.muted = false,
    this.solo = false,
    this.chokeGroup = 0,
    this.devices = const [],
  });

  final int note;
  final String name;
  final double gain;
  final double pan;
  final bool muted;
  final bool solo;
  final int chokeGroup;
  final List<DeviceSnapshot> devices;

  factory DrumPadSnapshot.fromMap(Map<dynamic, dynamic> map) => DrumPadSnapshot(
        note: (map['note'] as num?)?.toInt() ?? 0,
        name: map['name'] as String? ?? '',
        gain: (map['gain'] as num?)?.toDouble() ?? 1,
        pan: (map['pan'] as num?)?.toDouble() ?? 0.5,
        muted: map['muted'] == true,
        solo: map['solo'] == true,
        chokeGroup: (map['chokeGroup'] as num?)?.toInt() ?? 0,
        devices: (map['devices'] as List<dynamic>? ?? const [])
            .map((value) =>
                DeviceSnapshot.fromMap(value as Map<dynamic, dynamic>))
            .toList(growable: false),
      );
}

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
