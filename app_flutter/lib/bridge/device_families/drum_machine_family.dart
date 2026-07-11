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
        devices: parseDeviceList(map, 'devices'),
      );
}
