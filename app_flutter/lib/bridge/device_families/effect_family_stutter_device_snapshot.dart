part of '../device_snapshot.dart';

class StutterDeviceSnapshot extends EffectDeviceSnapshot {
  const StutterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    super.outputMix,
    super.outputWidth,
    required this.trigger,
    required this.captureMs,
    required this.rateSync,
    required this.rateBeats,
    required this.rateMs,
    required this.windowMs,
    required this.position,
    required this.gate,
    required this.fadeMs,
    required this.direction,
    required this.mix,
    required this.duck,
    required this.outputGain,
  }) : super(type: 'stutter_fx');

  final double trigger;
  final double captureMs;
  final double rateSync;
  final double rateBeats;
  final double rateMs;
  final double windowMs;
  final double position;
  final double gate;
  final double fadeMs;
  final double direction;
  final double mix;
  final double duck;
  final double outputGain;

  factory StutterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return StutterDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      trigger: (params['trigger'] as num?)?.toDouble() ?? 0.0,
      captureMs: (params['captureMs'] as num?)?.toDouble() ?? 500.0,
      rateSync: (params['rateSync'] as num?)?.toDouble() ?? 1.0,
      rateBeats: (params['rateBeats'] as num?)?.toDouble() ?? 0.25,
      rateMs: (params['rateMs'] as num?)?.toDouble() ?? 125.0,
      windowMs: (params['windowMs'] as num?)?.toDouble() ?? 80.0,
      position: (params['position'] as num?)?.toDouble() ?? 0.0,
      gate: (params['gate'] as num?)?.toDouble() ?? 0.85,
      fadeMs: (params['fadeMs'] as num?)?.toDouble() ?? 3.0,
      direction: (params['direction'] as num?)?.toDouble() ?? 0.0,
      mix: (params['mix'] as num?)?.toDouble() ?? 1.0,
      duck: (params['duck'] as num?)?.toDouble() ?? 0.45,
      outputGain: (params['outputGain'] as num?)?.toDouble() ?? 1.0,
      outputMix: (outputPanel['outputMix'] as num?)?.toDouble() ?? 1.0,
      outputWidth: (outputPanel['outputWidth'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  StutterDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? outputMix,
    double? outputWidth,
    double? trigger,
    double? captureMs,
    double? rateSync,
    double? rateBeats,
    double? rateMs,
    double? windowMs,
    double? position,
    double? gate,
    double? fadeMs,
    double? direction,
    double? mix,
    double? duck,
    double? outputGain,
  }) {
    return StutterDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      outputMix: outputMix ?? this.outputMix,
      outputWidth: outputWidth ?? this.outputWidth,
      trigger: trigger ?? this.trigger,
      captureMs: captureMs ?? this.captureMs,
      rateSync: rateSync ?? this.rateSync,
      rateBeats: rateBeats ?? this.rateBeats,
      rateMs: rateMs ?? this.rateMs,
      windowMs: windowMs ?? this.windowMs,
      position: position ?? this.position,
      gate: gate ?? this.gate,
      fadeMs: fadeMs ?? this.fadeMs,
      direction: direction ?? this.direction,
      mix: mix ?? this.mix,
      duck: duck ?? this.duck,
      outputGain: outputGain ?? this.outputGain,
    );
  }

  @override
  StutterDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'outputMix' => copyWith(outputMix: value),
      'outputWidth' => copyWith(outputWidth: value),
      'trigger' => copyWith(trigger: value),
      'captureMs' => copyWith(captureMs: value),
      'rateSync' => copyWith(rateSync: value),
      'rateBeats' => copyWith(rateBeats: value),
      'rateMs' => copyWith(rateMs: value),
      'windowMs' => copyWith(windowMs: value),
      'position' => copyWith(position: value),
      'gate' => copyWith(gate: value),
      'fadeMs' => copyWith(fadeMs: value),
      'direction' => copyWith(direction: value),
      'mix' => copyWith(mix: value),
      'duck' => copyWith(duck: value),
      'outputGain' => copyWith(outputGain: value),
      _ => this,
    };
  }
}
