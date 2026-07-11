part of '../device_snapshot.dart';

sealed class DrumGeneratorDeviceSnapshot extends DeviceSnapshot {
  const DrumGeneratorDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  });
}
