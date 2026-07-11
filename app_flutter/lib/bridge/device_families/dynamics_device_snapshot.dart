part of '../device_snapshot.dart';

sealed class DynamicsDeviceSnapshot extends DeviceSnapshot {
  const DynamicsDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.inputGain,
  });

  final double inputGain;
}
