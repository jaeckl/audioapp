part of '../device_snapshot.dart';

class DelayDeviceSnapshot extends EffectDeviceSnapshot {
  const DelayDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.delayTimeMs,
    required this.delayFeedback,
    this.delayTimeMode = 0,
    this.delayNoteCount = 1,
    this.delayBlurMode = 0,
    this.delayBlurAmount = 0.5,
    this.delayInputDucking = 0,
    this.delayLowCutHz = 20,
    this.delayHighCutHz = 20000,
  }) : super(type: 'delay');

  final double delayTimeMs;
  final double delayFeedback;
  final double delayTimeMode;
  final double delayNoteCount;
  final double delayBlurMode;
  final double delayBlurAmount;
  final double delayInputDucking;
  final double delayLowCutHz;
  final double delayHighCutHz;

  factory DelayDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DelayDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      delayTimeMs: (params['timeMs'] as num?)?.toDouble() ?? 250.0,
      delayFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.4,
      delayTimeMode: (params['timeMode'] as num?)?.toDouble() ?? 0.0,
      delayNoteCount: (params['noteCount'] as num?)?.toDouble() ?? 1.0,
      delayBlurMode: (params['blurMode'] as num?)?.toDouble() ?? 0.0,
      delayBlurAmount: (params['blurAmount'] as num?)?.toDouble() ?? 0.5,
      delayInputDucking: (params['inputDucking'] as num?)?.toDouble() ?? 0.0,
      delayLowCutHz: (params['lowCutHz'] as num?)?.toDouble() ?? 20.0,
      delayHighCutHz: (params['highCutHz'] as num?)?.toDouble() ?? 20000.0,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ??
          (params['outputMix'] as num?)?.toDouble() ??
          1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ??
          (params['outputWidth'] as num?)?.toDouble() ??
          1.0,
    );
  }

  @override
  DelayDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? delayTimeMs,
    double? delayFeedback,
    double? delayTimeMode,
    double? delayNoteCount,
    double? delayBlurMode,
    double? delayBlurAmount,
    double? delayInputDucking,
    double? delayLowCutHz,
    double? delayHighCutHz,
  }) {
    return DelayDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      delayTimeMs: delayTimeMs ?? this.delayTimeMs,
      delayFeedback: delayFeedback ?? this.delayFeedback,
      delayTimeMode: delayTimeMode ?? this.delayTimeMode,
      delayNoteCount: delayNoteCount ?? this.delayNoteCount,
      delayBlurMode: delayBlurMode ?? this.delayBlurMode,
      delayBlurAmount: delayBlurAmount ?? this.delayBlurAmount,
      delayInputDucking: delayInputDucking ?? this.delayInputDucking,
      delayLowCutHz: delayLowCutHz ?? this.delayLowCutHz,
      delayHighCutHz: delayHighCutHz ?? this.delayHighCutHz,
    );
  }

  @override
  DelayDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'timeMs' => copyWith(delayTimeMs: value),
      'feedback' => copyWith(delayFeedback: value),
      'timeMode' => copyWith(delayTimeMode: value),
      'noteCount' => copyWith(delayNoteCount: value),
      'blurMode' => copyWith(delayBlurMode: value),
      'blurAmount' => copyWith(delayBlurAmount: value),
      'inputDucking' => copyWith(delayInputDucking: value),
      'lowCutHz' => copyWith(delayLowCutHz: value),
      'highCutHz' => copyWith(delayHighCutHz: value),
      _ => this,
    };
  }
}
