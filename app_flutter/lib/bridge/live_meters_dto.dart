part 'live_meters_batch.dart';

/// Lightweight meter reading for one device, pushed via EventChannel.
class DeviceMeterReading {
  final String deviceId;
  final double gainReductionDb;
  final double inputLevel;
  final double leftLevel;
  final double rightLevel;
  final double loudnessLufs;
  final double correlation;
  final List<double> waveform;
  final List<double> spectrum;

  const DeviceMeterReading({
    required this.deviceId,
    this.gainReductionDb = 0,
    this.inputLevel = 0,
    this.leftLevel = 0,
    this.rightLevel = 0,
    this.loudnessLufs = -70,
    this.correlation = 0,
    this.waveform = const [],
    this.spectrum = const [],
  });

  factory DeviceMeterReading.fromMap(Map<dynamic, dynamic> map, String id) {
    return DeviceMeterReading(
      deviceId: id,
      gainReductionDb: (map['gr'] as num?)?.toDouble() ?? 0,
      inputLevel: (map['in'] as num?)?.toDouble() ?? 0,
      leftLevel: (map['left'] as num?)?.toDouble() ??
          (map['in'] as num?)?.toDouble() ??
          0,
      rightLevel: (map['right'] as num?)?.toDouble() ??
          (map['in'] as num?)?.toDouble() ??
          0,
      loudnessLufs: (map['lufs'] as num?)?.toDouble() ?? -70,
      correlation: (map['corr'] as num?)?.toDouble() ?? 0,
      waveform: (map['wave'] as List?)
              ?.whereType<num>()
              .map((v) => v.toDouble())
              .toList() ??
          const [],
      spectrum: (map['spectrum'] as List?)
              ?.whereType<num>()
              .map((v) => v.toDouble())
              .toList() ??
          const [],
    );
  }
}

/// Lightweight container for a batch of meter readings pushed from native.
