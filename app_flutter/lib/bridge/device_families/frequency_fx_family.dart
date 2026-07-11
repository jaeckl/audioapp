part of '../device_snapshot.dart';

sealed class FrequencyFxDeviceSnapshot extends DeviceSnapshot {
  const FrequencyFxDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  });
}
