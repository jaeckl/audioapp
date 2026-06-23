part of '../device_snapshot.dart';

/// Subtractive synth device snapshot.
class SubtractiveSynthDeviceSnapshot extends DeviceSnapshot {
  const SubtractiveSynthDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.osc1Shape,
    required this.osc2Shape,
    required this.osc1Octave,
    required this.osc1Semi,
    required this.osc1Detune,
    required this.osc2Octave,
    required this.osc2Semi,
    required this.osc2Detune,
    required this.oscMix,
    required this.osc1Sync,
    required this.osc2Sync,
    required this.noiseLevel,
    required this.oscMixMode,
    required this.unisonVoices,
    required this.unisonDetune,
    required this.filterEnvAmount,
    required this.filterAttack,
    required this.filterDecay,
    required this.filterSustain,
    required this.filterRelease,
    required this.glideMs,
    required this.velocitySensitivity,
    required this.preHpCutoff,
    required this.preHpRes,
    required this.preDrive,
    required this.mixFeedback,
    required this.globalPitch,
    required this.filterKeyTrack,
    required this.filterDrive,
    required this.filterShaper,
    required this.filterFm,
    required this.filterShaperMode,
    required this.synthLegato,
    required this.synthMono,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.filterCutoff,
    required this.filterQ,
    required this.filterMode,
  }) : super(type: 'subtractive_synth');

  final double osc1Shape;
  final double osc2Shape;
  final double osc1Octave;
  final double osc1Semi;
  final double osc1Detune;
  final double osc2Octave;
  final double osc2Semi;
  final double osc2Detune;
  final double oscMix;
  final double osc1Sync;
  final double osc2Sync;
  final double noiseLevel;
  final int oscMixMode;
  final double unisonVoices;
  final double unisonDetune;
  final double filterEnvAmount;
  final double filterAttack;
  final double filterDecay;
  final double filterSustain;
  final double filterRelease;
  final double glideMs;
  final double velocitySensitivity;
  final double preHpCutoff;
  final double preHpRes;
  final double preDrive;
  final double mixFeedback;
  final double globalPitch;
  final double filterKeyTrack;
  final double filterDrive;
  final double filterShaper;
  final double filterFm;
  final int filterShaperMode;
  final double synthLegato;
  final double synthMono;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double filterCutoff;
  final double filterQ;
  final int filterMode;

  factory SubtractiveSynthDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return SubtractiveSynthDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      osc1Shape: readOscShape(params, 'osc1Shape', 'osc1Wave', 0.5),
      osc2Shape: readOscShape(params, 'osc2Shape', 'osc2Wave', 0.5),
      osc1Octave: (params['osc1Octave'] as num?)?.toDouble() ?? 0.5,
      osc1Semi: (params['osc1Semi'] as num?)?.toDouble() ?? 0.0,
      osc1Detune: (params['osc1Detune'] as num?)?.toDouble() ?? 0.5,
      osc2Octave: (params['osc2Octave'] as num?)?.toDouble() ?? 0.5,
      osc2Semi: (params['osc2Semi'] as num?)?.toDouble() ?? 0.0,
      osc2Detune: (params['osc2Detune'] as num?)?.toDouble() ?? 0.5,
      oscMix: (params['oscMix'] as num?)?.toDouble() ?? deriveOscMixFromLegacyLevels(params),
      osc1Sync: (params['osc1Sync'] as num?)?.toDouble() ?? 0.0,
      osc2Sync: (params['osc2Sync'] as num?)?.toDouble() ?? 0.0,
      noiseLevel: (params['noiseLevel'] as num?)?.toDouble() ?? 0.0,
      oscMixMode: (params['oscMixMode'] as num?)?.toInt() ?? 0,
      unisonVoices: (params['unisonVoices'] as num?)?.toDouble() ?? 0.0,
      unisonDetune: (params['unisonDetune'] as num?)?.toDouble() ?? 0.35,
      filterEnvAmount: (params['filterEnvAmount'] as num?)?.toDouble() ?? 0.5,
      filterAttack: (params['filterAttack'] as num?)?.toDouble() ?? 0.05,
      filterDecay: (params['filterDecay'] as num?)?.toDouble() ?? 0.35,
      filterSustain: (params['filterSustain'] as num?)?.toDouble() ?? 0.4,
      filterRelease: (params['filterRelease'] as num?)?.toDouble() ?? 0.45,
      glideMs: (params['glideMs'] as num?)?.toDouble() ?? 0.0,
      velocitySensitivity: (params['velocitySensitivity'] as num?)?.toDouble() ?? 1.0,
      preHpCutoff: (params['preHpCutoff'] as num?)?.toDouble() ?? 0.0,
      preHpRes: (params['preHpRes'] as num?)?.toDouble() ?? 0.2,
      preDrive: (params['preDrive'] as num?)?.toDouble() ?? 0.0,
      mixFeedback: (params['mixFeedback'] as num?)?.toDouble() ?? 0.0,
      globalPitch: (params['globalPitch'] as num?)?.toDouble() ?? 0.5,
      filterKeyTrack: (params['filterKeyTrack'] as num?)?.toDouble() ?? 0.0,
      filterDrive: (params['filterDrive'] as num?)?.toDouble() ?? 0.0,
      filterShaper: (params['filterShaper'] as num?)?.toDouble() ?? 0.0,
      filterFm: (params['filterFm'] as num?)?.toDouble() ?? 0.0,
      filterShaperMode: (params['filterShaperMode'] as num?)?.toInt() ?? 1,
      synthLegato: (params['synthLegato'] as num?)?.toDouble() ?? 0.0,
      synthMono: (params['synthMono'] as num?)?.toDouble() ?? 0.0,
      attack: (params['attack'] as num?)?.toDouble() ?? 0.01,
      decay: (params['decay'] as num?)?.toDouble() ?? 0.3,
      sustain: (params['sustain'] as num?)?.toDouble() ?? 0.7,
      release: (params['release'] as num?)?.toDouble() ?? 0.4,
      filterCutoff: (params['filterCutoff'] as num?)?.toDouble() ?? 1.0,
      filterQ: (params['filterQ'] as num?)?.toDouble() ?? 0.35,
      filterMode: (params['filterMode'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  SubtractiveSynthDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? osc1Shape,
    double? osc2Shape,
    double? osc1Octave,
    double? osc1Semi,
    double? osc1Detune,
    double? osc2Octave,
    double? osc2Semi,
    double? osc2Detune,
    double? oscMix,
    double? osc1Sync,
    double? osc2Sync,
    double? noiseLevel,
    int? oscMixMode,
    double? unisonVoices,
    double? unisonDetune,
    double? filterEnvAmount,
    double? filterAttack,
    double? filterDecay,
    double? filterSustain,
    double? filterRelease,
    double? glideMs,
    double? velocitySensitivity,
    double? preHpCutoff,
    double? preHpRes,
    double? preDrive,
    double? mixFeedback,
    double? globalPitch,
    double? filterKeyTrack,
    double? filterDrive,
    double? filterShaper,
    double? filterFm,
    int? filterShaperMode,
    double? synthLegato,
    double? synthMono,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    double? filterCutoff,
    double? filterQ,
    int? filterMode,
  }) {
    return SubtractiveSynthDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      osc1Shape: osc1Shape ?? this.osc1Shape,
      osc2Shape: osc2Shape ?? this.osc2Shape,
      osc1Octave: osc1Octave ?? this.osc1Octave,
      osc1Semi: osc1Semi ?? this.osc1Semi,
      osc1Detune: osc1Detune ?? this.osc1Detune,
      osc2Octave: osc2Octave ?? this.osc2Octave,
      osc2Semi: osc2Semi ?? this.osc2Semi,
      osc2Detune: osc2Detune ?? this.osc2Detune,
      oscMix: oscMix ?? this.oscMix,
      osc1Sync: osc1Sync ?? this.osc1Sync,
      osc2Sync: osc2Sync ?? this.osc2Sync,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      oscMixMode: oscMixMode ?? this.oscMixMode,
      unisonVoices: unisonVoices ?? this.unisonVoices,
      unisonDetune: unisonDetune ?? this.unisonDetune,
      filterEnvAmount: filterEnvAmount ?? this.filterEnvAmount,
      filterAttack: filterAttack ?? this.filterAttack,
      filterDecay: filterDecay ?? this.filterDecay,
      filterSustain: filterSustain ?? this.filterSustain,
      filterRelease: filterRelease ?? this.filterRelease,
      glideMs: glideMs ?? this.glideMs,
      velocitySensitivity: velocitySensitivity ?? this.velocitySensitivity,
      preHpCutoff: preHpCutoff ?? this.preHpCutoff,
      preHpRes: preHpRes ?? this.preHpRes,
      preDrive: preDrive ?? this.preDrive,
      mixFeedback: mixFeedback ?? this.mixFeedback,
      globalPitch: globalPitch ?? this.globalPitch,
      filterKeyTrack: filterKeyTrack ?? this.filterKeyTrack,
      filterDrive: filterDrive ?? this.filterDrive,
      filterShaper: filterShaper ?? this.filterShaper,
      filterFm: filterFm ?? this.filterFm,
      filterShaperMode: filterShaperMode ?? this.filterShaperMode,
      synthLegato: synthLegato ?? this.synthLegato,
      synthMono: synthMono ?? this.synthMono,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      filterCutoff: filterCutoff ?? this.filterCutoff,
      filterQ: filterQ ?? this.filterQ,
      filterMode: filterMode ?? this.filterMode,
    );
  }

  @override
  SubtractiveSynthDeviceSnapshot withParameter(String parameterId, double value) {
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
      'osc1Shape' => copyWith(osc1Shape: value.clamp(0.0, 1.0)),
      'osc2Shape' => copyWith(osc2Shape: value.clamp(0.0, 1.0)),
      'osc1Octave' => copyWith(osc1Octave: value),
      'osc1Semi' => copyWith(osc1Semi: value),
      'osc1Detune' => copyWith(osc1Detune: value),
      'osc2Octave' => copyWith(osc2Octave: value),
      'osc2Semi' => copyWith(osc2Semi: value),
      'osc2Detune' => copyWith(osc2Detune: value),
      'oscMix' => copyWith(oscMix: value.clamp(0.0, 1.0)),
      'osc1Sync' => copyWith(osc1Sync: value.clamp(0.0, 1.0)),
      'osc2Sync' => copyWith(osc2Sync: value.clamp(0.0, 1.0)),
      'noiseLevel' => copyWith(noiseLevel: value),
      'oscMixMode' => copyWith(oscMixMode: value.round().clamp(0, 4)),
      'unisonVoices' => copyWith(unisonVoices: value),
      'unisonDetune' => copyWith(unisonDetune: value),
      'filterEnvAmount' => copyWith(filterEnvAmount: value),
      'filterAttack' => copyWith(filterAttack: value),
      'filterDecay' => copyWith(filterDecay: value),
      'filterSustain' => copyWith(filterSustain: value),
      'filterRelease' => copyWith(filterRelease: value),
      'glideMs' => copyWith(glideMs: value),
      'velocitySensitivity' => copyWith(velocitySensitivity: value),
      'preHpCutoff' => copyWith(preHpCutoff: value),
      'preHpRes' => copyWith(preHpRes: value),
      'preDrive' => copyWith(preDrive: value),
      'mixFeedback' => copyWith(mixFeedback: value),
      'globalPitch' => copyWith(globalPitch: value),
      'filterKeyTrack' => copyWith(filterKeyTrack: value),
      'filterDrive' => copyWith(filterDrive: value),
      'filterShaper' => copyWith(filterShaper: value),
      'filterFm' => copyWith(filterFm: value),
      'filterShaperMode' => copyWith(filterShaperMode: value.round().clamp(0, 3)),
      'synthLegato' => copyWith(synthLegato: value >= 0.5 ? 1.0 : 0.0),
      'synthMono' => copyWith(synthMono: value >= 0.5 ? 1.0 : 0.0),
      _ => this,
    };
  }
}