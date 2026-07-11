part of 'live_meters_dto.dart';

class LiveMetersBatch {
  final List<DeviceMeterReading> meters;

  const LiveMetersBatch({required this.meters});

  factory LiveMetersBatch.fromMap(Map<dynamic, dynamic> map) {
    final raw = map['meters'];
    if (raw is! Map) {
      return const LiveMetersBatch(meters: []);
    }

    final list = <DeviceMeterReading>[];
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is Map) {
        list.add(DeviceMeterReading.fromMap(value, entry.key.toString()));
      }
    }
    return LiveMetersBatch(meters: list);
  }
}
