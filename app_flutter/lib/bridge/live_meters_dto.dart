/// Lightweight meter reading for one device, pushed via EventChannel.
class DeviceMeterReading {
  final String deviceId;
  final double gainReductionDb;
  final double inputLevel;

  const DeviceMeterReading({
    required this.deviceId,
    this.gainReductionDb = 0,
    this.inputLevel = 0,
  });

  factory DeviceMeterReading.fromMap(Map<String, dynamic> map, String id) {
    return DeviceMeterReading(
      deviceId: id,
      gainReductionDb: (map['gr'] as num?)?.toDouble() ?? 0,
      inputLevel: (map['in'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Lightweight container for a batch of meter readings pushed from native.
class LiveMetersBatch {
  final List<DeviceMeterReading> meters;

  const LiveMetersBatch({required this.meters});

  factory LiveMetersBatch.fromMap(Map<dynamic, dynamic> map) {
    final raw = map['meters'] as Map<dynamic, dynamic>? ?? {};
    final list = raw.entries
        .whereType<MapEntry<dynamic, dynamic>>()
        .map((e) => DeviceMeterReading.fromMap(
              e.value as Map<String, dynamic>,
              e.key.toString(),
            ))
        .toList();
    return LiveMetersBatch(meters: list);
  }
}