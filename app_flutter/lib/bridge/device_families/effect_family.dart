part of '../device_snapshot.dart';

sealed class EffectDeviceSnapshot extends DeviceSnapshot {
  const EffectDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    this.outputMix = 1.0,
    this.outputWidth = 1.0,
  });

  final double outputMix;
  final double outputWidth;
}
