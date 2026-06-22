part of '../device_snapshot.dart';

/// Simple sampler device snapshot.
class SamplerDeviceSnapshot extends DeviceSnapshot {
  const SamplerDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.sampleId,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.filterCutoff,
    required this.filterQ,
    required this.filterMode,
    required this.trimStartSec,
    required this.trimEndSec,
    required this.regionStartSec,
    required this.regionEndSec,
    required this.rootPitch,
    required this.rootFineTune,
    required this.playbackMode,
    required this.filterEnvAmount,
    required this.filterAttack,
    required this.filterDecay,
    required this.filterSustain,
    required this.filterRelease,
  }) : super(type: 'simple_sampler');

  final String sampleId;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double filterCutoff;
  final double filterQ;
  final int filterMode;
  final double trimStartSec;
  final double trimEndSec;
  final double regionStartSec;
  final double regionEndSec;
  final double rootPitch;
  final double rootFineTune;
  final int playbackMode;
  final double filterEnvAmount;
  final double filterAttack;
  final double filterDecay;
  final double filterSustain;
  final double filterRelease;

  factory SamplerDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return SamplerDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      sampleId: params['sampleId'] as String? ?? '',
      attack: (params['attack'] as num?)?.toDouble() ?? 0.01,
      decay: (params['decay'] as num?)?.toDouble() ?? 0.3,
      sustain: (params['sustain'] as num?)?.toDouble() ?? 0.7,
      release: (params['release'] as num?)?.toDouble() ?? 0.4,
      filterCutoff: (params['filterCutoff'] as num?)?.toDouble() ?? 1.0,
      filterQ: (params['filterQ'] as num?)?.toDouble() ?? 0.35,
      filterMode: (params['filterMode'] as num?)?.toInt() ?? 0,
      trimStartSec: (params['trimStartSec'] as num?)?.toDouble() ?? 0.0,
      trimEndSec: (params['trimEndSec'] as num?)?.toDouble() ?? 0.0,
      regionStartSec: (params['regionStartSec'] as num?)?.toDouble() ?? 0.0,
      regionEndSec: (params['regionEndSec'] as num?)?.toDouble() ?? 0.0,
      rootPitch: (params['rootPitch'] as num?)?.toDouble() ?? 60.0,
      rootFineTune: (params['rootFineTune'] as num?)?.toDouble() ?? 0.0,
      playbackMode: params.containsKey('playbackMode')
          ? (params['playbackMode'] as num?)?.toInt() ?? 0
          : (((params['regionEndSec'] as num?)?.toDouble() ?? 0.0) > 0 ? 1 : 0),
      filterEnvAmount: (params['filterEnvAmount'] as num?)?.toDouble() ?? 0.5,
      filterAttack: (params['filterAttack'] as num?)?.toDouble() ?? 0.01,
      filterDecay: (params['filterDecay'] as num?)?.toDouble() ?? 0.35,
      filterSustain: (params['filterSustain'] as num?)?.toDouble() ?? 0.7,
      filterRelease: (params['filterRelease'] as num?)?.toDouble() ?? 0.4,
    );
  }

  @override
  SamplerDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    String? sampleId,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    double? filterCutoff,
    double? filterQ,
    int? filterMode,
    double? trimStartSec,
    double? trimEndSec,
    double? regionStartSec,
    double? regionEndSec,
    double? rootPitch,
    double? rootFineTune,
    int? playbackMode,
    double? filterEnvAmount,
    double? filterAttack,
    double? filterDecay,
    double? filterSustain,
    double? filterRelease,
  }) {
    return SamplerDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      sampleId: sampleId ?? this.sampleId,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      filterCutoff: filterCutoff ?? this.filterCutoff,
      filterQ: filterQ ?? this.filterQ,
      filterMode: filterMode ?? this.filterMode,
      trimStartSec: trimStartSec ?? this.trimStartSec,
      trimEndSec: trimEndSec ?? this.trimEndSec,
      regionStartSec: regionStartSec ?? this.regionStartSec,
      regionEndSec: regionEndSec ?? this.regionEndSec,
      rootPitch: rootPitch ?? this.rootPitch,
      rootFineTune: rootFineTune ?? this.rootFineTune,
      playbackMode: playbackMode ?? this.playbackMode,
      filterEnvAmount: filterEnvAmount ?? this.filterEnvAmount,
      filterAttack: filterAttack ?? this.filterAttack,
      filterDecay: filterDecay ?? this.filterDecay,
      filterSustain: filterSustain ?? this.filterSustain,
      filterRelease: filterRelease ?? this.filterRelease,
    );
  }

  @override
  SamplerDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'attack' => copyWith(attack: value),
      'decay' => copyWith(decay: value),
      'sustain' => copyWith(sustain: value),
      'release' => copyWith(release: value),
      'filterCutoff' => copyWith(filterCutoff: value),
      'filterQ' => copyWith(filterQ: value),
      'filterMode' => copyWith(filterMode: value.round().clamp(0, 5)),
      'trimStartSec' => copyWith(trimStartSec: value),
      'trimEndSec' => copyWith(trimEndSec: value),
      'regionStartSec' => copyWith(regionStartSec: value),
      'regionEndSec' => copyWith(regionEndSec: value),
      'rootPitch' => copyWith(rootPitch: value.clamp(0.0, 127.0)),
      'rootFineTune' => copyWith(rootFineTune: value.clamp(-100.0, 100.0)),
      'playbackMode' => copyWith(playbackMode: value.round().clamp(0, 2)),
      'filterEnvAmount' => copyWith(filterEnvAmount: value),
      'filterAttack' => copyWith(filterAttack: value),
      'filterDecay' => copyWith(filterDecay: value),
      'filterSustain' => copyWith(filterSustain: value),
      'filterRelease' => copyWith(filterRelease: value),
      _ => this,
    };
  }
}