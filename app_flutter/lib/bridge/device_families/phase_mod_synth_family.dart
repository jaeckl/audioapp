part of '../device_snapshot.dart';

/// Phase-modulation (FM) synth device snapshot.
class PhaseModSynthDeviceSnapshot extends DeviceSnapshot {
  const PhaseModSynthDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.pmOp1Ratio,
    required this.pmOp1Fine,
    required this.pmOp1Level,
    required this.pmOp1Wave,
    required this.pmOp1Attack,
    required this.pmOp1Decay,
    required this.pmOp1Sustain,
    required this.pmOp1Release,
    required this.pmOp1VelSense,
    required this.pmOp1KeyTrack,
    required this.pmOp2Ratio,
    required this.pmOp2Fine,
    required this.pmOp2Level,
    required this.pmOp2Wave,
    required this.pmOp2Attack,
    required this.pmOp2Decay,
    required this.pmOp2Sustain,
    required this.pmOp2Release,
    required this.pmOp2VelSense,
    required this.pmOp2KeyTrack,
    required this.pmOp3Ratio,
    required this.pmOp3Fine,
    required this.pmOp3Level,
    required this.pmOp3Wave,
    required this.pmOp3Attack,
    required this.pmOp3Decay,
    required this.pmOp3Sustain,
    required this.pmOp3Release,
    required this.pmOp3VelSense,
    required this.pmOp3KeyTrack,
    required this.pmOp4Ratio,
    required this.pmOp4Fine,
    required this.pmOp4Level,
    required this.pmOp4Wave,
    required this.pmOp4Attack,
    required this.pmOp4Decay,
    required this.pmOp4Sustain,
    required this.pmOp4Release,
    required this.pmOp4VelSense,
    required this.pmOp4KeyTrack,
    required this.pmAlgoIndex,
    required this.pmFeedback,
    required this.pmUnisonVoices,
    required this.pmUnisonDetune,
    required this.pmGlide,
    required this.pmMono,
    required this.pmLegato,
    required this.pmMasterVol,
    required this.pmLfoRate,
    required this.pmLfoShape,
    required this.pmLfoAmount,
    required this.pmLfoDest,
    required this.pmVibratoDepth,
    required this.pmVibratoRate,
    required this.filterCutoff,
    required this.filterQ,
    required this.filterMode,
    required this.filterEnvAmount,
    required this.filterAttack,
    required this.filterDecay,
    required this.filterSustain,
    required this.filterRelease,
    required this.filterKeyTrack,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
  }) : super(type: 'phase_mod_synth');

  final double pmOp1Ratio;
  final double pmOp1Fine;
  final double pmOp1Level;
  final double pmOp1Wave;
  final double pmOp1Attack;
  final double pmOp1Decay;
  final double pmOp1Sustain;
  final double pmOp1Release;
  final double pmOp1VelSense;
  final double pmOp1KeyTrack;

  final double pmOp2Ratio;
  final double pmOp2Fine;
  final double pmOp2Level;
  final double pmOp2Wave;
  final double pmOp2Attack;
  final double pmOp2Decay;
  final double pmOp2Sustain;
  final double pmOp2Release;
  final double pmOp2VelSense;
  final double pmOp2KeyTrack;

  final double pmOp3Ratio;
  final double pmOp3Fine;
  final double pmOp3Level;
  final double pmOp3Wave;
  final double pmOp3Attack;
  final double pmOp3Decay;
  final double pmOp3Sustain;
  final double pmOp3Release;
  final double pmOp3VelSense;
  final double pmOp3KeyTrack;

  final double pmOp4Ratio;
  final double pmOp4Fine;
  final double pmOp4Level;
  final double pmOp4Wave;
  final double pmOp4Attack;
  final double pmOp4Decay;
  final double pmOp4Sustain;
  final double pmOp4Release;
  final double pmOp4VelSense;
  final double pmOp4KeyTrack;

  final int pmAlgoIndex;
  final double pmFeedback;
  final double pmUnisonVoices;
  final double pmUnisonDetune;
  final double pmGlide;
  final double pmMono;
  final double pmLegato;
  final double pmMasterVol;
  final double pmLfoRate;
  final double pmLfoShape;
  final double pmLfoAmount;
  final int pmLfoDest;
  final double pmVibratoDepth;
  final double pmVibratoRate;

  final double filterCutoff;
  final double filterQ;
  final int filterMode;
  final double filterEnvAmount;
  final double filterAttack;
  final double filterDecay;
  final double filterSustain;
  final double filterRelease;
  final double filterKeyTrack;

  final double attack;
  final double decay;
  final double sustain;
  final double release;

  factory PhaseModSynthDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return PhaseModSynthDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      pmOp1Ratio: (params['pmOp1Ratio'] as num?)?.toDouble() ?? 0.0625,
      pmOp1Fine: (params['pmOp1Fine'] as num?)?.toDouble() ?? 0.5,
      pmOp1Level: (params['pmOp1Level'] as num?)?.toDouble() ?? 0.8,
      pmOp1Wave: (params['pmOp1Wave'] as num?)?.toDouble() ?? 0.0,
      pmOp1Attack: (params['pmOp1Attack'] as num?)?.toDouble() ?? 0.01,
      pmOp1Decay: (params['pmOp1Decay'] as num?)?.toDouble() ?? 0.3,
      pmOp1Sustain: (params['pmOp1Sustain'] as num?)?.toDouble() ?? 0.8,
      pmOp1Release: (params['pmOp1Release'] as num?)?.toDouble() ?? 0.4,
      pmOp1VelSense: (params['pmOp1VelSense'] as num?)?.toDouble() ?? 1.0,
      pmOp1KeyTrack: (params['pmOp1KeyTrack'] as num?)?.toDouble() ?? 0.0,
      pmOp2Ratio: (params['pmOp2Ratio'] as num?)?.toDouble() ?? 0.4375,
      pmOp2Fine: (params['pmOp2Fine'] as num?)?.toDouble() ?? 0.5,
      pmOp2Level: (params['pmOp2Level'] as num?)?.toDouble() ?? 0.4,
      pmOp2Wave: (params['pmOp2Wave'] as num?)?.toDouble() ?? 0.0,
      pmOp2Attack: (params['pmOp2Attack'] as num?)?.toDouble() ?? 0.01,
      pmOp2Decay: (params['pmOp2Decay'] as num?)?.toDouble() ?? 0.3,
      pmOp2Sustain: (params['pmOp2Sustain'] as num?)?.toDouble() ?? 0.8,
      pmOp2Release: (params['pmOp2Release'] as num?)?.toDouble() ?? 0.4,
      pmOp2VelSense: (params['pmOp2VelSense'] as num?)?.toDouble() ?? 1.0,
      pmOp2KeyTrack: (params['pmOp2KeyTrack'] as num?)?.toDouble() ?? 0.0,
      pmOp3Ratio: (params['pmOp3Ratio'] as num?)?.toDouble() ?? 0.75,
      pmOp3Fine: (params['pmOp3Fine'] as num?)?.toDouble() ?? 0.5,
      pmOp3Level: (params['pmOp3Level'] as num?)?.toDouble() ?? 0.0,
      pmOp3Wave: (params['pmOp3Wave'] as num?)?.toDouble() ?? 0.0,
      pmOp3Attack: (params['pmOp3Attack'] as num?)?.toDouble() ?? 0.01,
      pmOp3Decay: (params['pmOp3Decay'] as num?)?.toDouble() ?? 0.3,
      pmOp3Sustain: (params['pmOp3Sustain'] as num?)?.toDouble() ?? 0.8,
      pmOp3Release: (params['pmOp3Release'] as num?)?.toDouble() ?? 0.4,
      pmOp3VelSense: (params['pmOp3VelSense'] as num?)?.toDouble() ?? 1.0,
      pmOp3KeyTrack: (params['pmOp3KeyTrack'] as num?)?.toDouble() ?? 0.0,
      pmOp4Ratio: (params['pmOp4Ratio'] as num?)?.toDouble() ?? 0.375,
      pmOp4Fine: (params['pmOp4Fine'] as num?)?.toDouble() ?? 0.5,
      pmOp4Level: (params['pmOp4Level'] as num?)?.toDouble() ?? 0.0,
      pmOp4Wave: (params['pmOp4Wave'] as num?)?.toDouble() ?? 0.0,
      pmOp4Attack: (params['pmOp4Attack'] as num?)?.toDouble() ?? 0.01,
      pmOp4Decay: (params['pmOp4Decay'] as num?)?.toDouble() ?? 0.3,
      pmOp4Sustain: (params['pmOp4Sustain'] as num?)?.toDouble() ?? 0.8,
      pmOp4Release: (params['pmOp4Release'] as num?)?.toDouble() ?? 0.4,
      pmOp4VelSense: (params['pmOp4VelSense'] as num?)?.toDouble() ?? 1.0,
      pmOp4KeyTrack: (params['pmOp4KeyTrack'] as num?)?.toDouble() ?? 0.0,
      pmAlgoIndex: (params['pmAlgoIndex'] as num?)?.toInt() ?? 0,
      pmFeedback: (params['pmFeedback'] as num?)?.toDouble() ?? 0.0,
      pmUnisonVoices: (params['pmUnisonVoices'] as num?)?.toDouble() ?? 0.0,
      pmUnisonDetune: (params['pmUnisonDetune'] as num?)?.toDouble() ?? 0.15,
      pmGlide: (params['pmGlide'] as num?)?.toDouble() ?? 0.0,
      pmMono: (params['pmMono'] as num?)?.toDouble() ?? 0.0,
      pmLegato: (params['pmLegato'] as num?)?.toDouble() ?? 0.0,
      pmMasterVol: (params['pmMasterVol'] as num?)?.toDouble() ?? 0.85,
      pmLfoRate: (params['pmLfoRate'] as num?)?.toDouble() ?? 0.2,
      pmLfoShape: (params['pmLfoShape'] as num?)?.toDouble() ?? 0.0,
      pmLfoAmount: (params['pmLfoAmount'] as num?)?.toDouble() ?? 0.0,
      pmLfoDest: (params['pmLfoDest'] as num?)?.toInt() ?? 0,
      pmVibratoDepth: (params['pmVibratoDepth'] as num?)?.toDouble() ?? 0.0,
      pmVibratoRate: (params['pmVibratoRate'] as num?)?.toDouble() ?? 0.3,
      filterCutoff: (params['filterCutoff'] as num?)?.toDouble() ?? 1.0,
      filterQ: (params['filterQ'] as num?)?.toDouble() ?? 0.35,
      filterMode: (params['filterMode'] as num?)?.toInt() ?? 0,
      filterEnvAmount: (params['filterEnvAmount'] as num?)?.toDouble() ?? 0.5,
      filterAttack: (params['filterAttack'] as num?)?.toDouble() ?? 0.05,
      filterDecay: (params['filterDecay'] as num?)?.toDouble() ?? 0.35,
      filterSustain: (params['filterSustain'] as num?)?.toDouble() ?? 0.4,
      filterRelease: (params['filterRelease'] as num?)?.toDouble() ?? 0.45,
      filterKeyTrack: (params['filterKeyTrack'] as num?)?.toDouble() ?? 0.0,
      attack: (params['attack'] as num?)?.toDouble() ?? 0.01,
      decay: (params['decay'] as num?)?.toDouble() ?? 0.3,
      sustain: (params['sustain'] as num?)?.toDouble() ?? 0.7,
      release: (params['release'] as num?)?.toDouble() ?? 0.4,
    );
  }

  @override
  PhaseModSynthDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? pmOp1Ratio,
    double? pmOp1Fine,
    double? pmOp1Level,
    double? pmOp1Wave,
    double? pmOp1Attack,
    double? pmOp1Decay,
    double? pmOp1Sustain,
    double? pmOp1Release,
    double? pmOp1VelSense,
    double? pmOp1KeyTrack,
    double? pmOp2Ratio,
    double? pmOp2Fine,
    double? pmOp2Level,
    double? pmOp2Wave,
    double? pmOp2Attack,
    double? pmOp2Decay,
    double? pmOp2Sustain,
    double? pmOp2Release,
    double? pmOp2VelSense,
    double? pmOp2KeyTrack,
    double? pmOp3Ratio,
    double? pmOp3Fine,
    double? pmOp3Level,
    double? pmOp3Wave,
    double? pmOp3Attack,
    double? pmOp3Decay,
    double? pmOp3Sustain,
    double? pmOp3Release,
    double? pmOp3VelSense,
    double? pmOp3KeyTrack,
    double? pmOp4Ratio,
    double? pmOp4Fine,
    double? pmOp4Level,
    double? pmOp4Wave,
    double? pmOp4Attack,
    double? pmOp4Decay,
    double? pmOp4Sustain,
    double? pmOp4Release,
    double? pmOp4VelSense,
    double? pmOp4KeyTrack,
    int? pmAlgoIndex,
    double? pmFeedback,
    double? pmUnisonVoices,
    double? pmUnisonDetune,
    double? pmGlide,
    double? pmMono,
    double? pmLegato,
    double? pmMasterVol,
    double? pmLfoRate,
    double? pmLfoShape,
    double? pmLfoAmount,
    int? pmLfoDest,
    double? pmVibratoDepth,
    double? pmVibratoRate,
    double? filterCutoff,
    double? filterQ,
    int? filterMode,
    double? filterEnvAmount,
    double? filterAttack,
    double? filterDecay,
    double? filterSustain,
    double? filterRelease,
    double? filterKeyTrack,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
  }) {
    return PhaseModSynthDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      pmOp1Ratio: pmOp1Ratio ?? this.pmOp1Ratio,
      pmOp1Fine: pmOp1Fine ?? this.pmOp1Fine,
      pmOp1Level: pmOp1Level ?? this.pmOp1Level,
      pmOp1Wave: pmOp1Wave ?? this.pmOp1Wave,
      pmOp1Attack: pmOp1Attack ?? this.pmOp1Attack,
      pmOp1Decay: pmOp1Decay ?? this.pmOp1Decay,
      pmOp1Sustain: pmOp1Sustain ?? this.pmOp1Sustain,
      pmOp1Release: pmOp1Release ?? this.pmOp1Release,
      pmOp1VelSense: pmOp1VelSense ?? this.pmOp1VelSense,
      pmOp1KeyTrack: pmOp1KeyTrack ?? this.pmOp1KeyTrack,
      pmOp2Ratio: pmOp2Ratio ?? this.pmOp2Ratio,
      pmOp2Fine: pmOp2Fine ?? this.pmOp2Fine,
      pmOp2Level: pmOp2Level ?? this.pmOp2Level,
      pmOp2Wave: pmOp2Wave ?? this.pmOp2Wave,
      pmOp2Attack: pmOp2Attack ?? this.pmOp2Attack,
      pmOp2Decay: pmOp2Decay ?? this.pmOp2Decay,
      pmOp2Sustain: pmOp2Sustain ?? this.pmOp2Sustain,
      pmOp2Release: pmOp2Release ?? this.pmOp2Release,
      pmOp2VelSense: pmOp2VelSense ?? this.pmOp2VelSense,
      pmOp2KeyTrack: pmOp2KeyTrack ?? this.pmOp2KeyTrack,
      pmOp3Ratio: pmOp3Ratio ?? this.pmOp3Ratio,
      pmOp3Fine: pmOp3Fine ?? this.pmOp3Fine,
      pmOp3Level: pmOp3Level ?? this.pmOp3Level,
      pmOp3Wave: pmOp3Wave ?? this.pmOp3Wave,
      pmOp3Attack: pmOp3Attack ?? this.pmOp3Attack,
      pmOp3Decay: pmOp3Decay ?? this.pmOp3Decay,
      pmOp3Sustain: pmOp3Sustain ?? this.pmOp3Sustain,
      pmOp3Release: pmOp3Release ?? this.pmOp3Release,
      pmOp3VelSense: pmOp3VelSense ?? this.pmOp3VelSense,
      pmOp3KeyTrack: pmOp3KeyTrack ?? this.pmOp3KeyTrack,
      pmOp4Ratio: pmOp4Ratio ?? this.pmOp4Ratio,
      pmOp4Fine: pmOp4Fine ?? this.pmOp4Fine,
      pmOp4Level: pmOp4Level ?? this.pmOp4Level,
      pmOp4Wave: pmOp4Wave ?? this.pmOp4Wave,
      pmOp4Attack: pmOp4Attack ?? this.pmOp4Attack,
      pmOp4Decay: pmOp4Decay ?? this.pmOp4Decay,
      pmOp4Sustain: pmOp4Sustain ?? this.pmOp4Sustain,
      pmOp4Release: pmOp4Release ?? this.pmOp4Release,
      pmOp4VelSense: pmOp4VelSense ?? this.pmOp4VelSense,
      pmOp4KeyTrack: pmOp4KeyTrack ?? this.pmOp4KeyTrack,
      pmAlgoIndex: pmAlgoIndex ?? this.pmAlgoIndex,
      pmFeedback: pmFeedback ?? this.pmFeedback,
      pmUnisonVoices: pmUnisonVoices ?? this.pmUnisonVoices,
      pmUnisonDetune: pmUnisonDetune ?? this.pmUnisonDetune,
      pmGlide: pmGlide ?? this.pmGlide,
      pmMono: pmMono ?? this.pmMono,
      pmLegato: pmLegato ?? this.pmLegato,
      pmMasterVol: pmMasterVol ?? this.pmMasterVol,
      pmLfoRate: pmLfoRate ?? this.pmLfoRate,
      pmLfoShape: pmLfoShape ?? this.pmLfoShape,
      pmLfoAmount: pmLfoAmount ?? this.pmLfoAmount,
      pmLfoDest: pmLfoDest ?? this.pmLfoDest,
      pmVibratoDepth: pmVibratoDepth ?? this.pmVibratoDepth,
      pmVibratoRate: pmVibratoRate ?? this.pmVibratoRate,
      filterCutoff: filterCutoff ?? this.filterCutoff,
      filterQ: filterQ ?? this.filterQ,
      filterMode: filterMode ?? this.filterMode,
      filterEnvAmount: filterEnvAmount ?? this.filterEnvAmount,
      filterAttack: filterAttack ?? this.filterAttack,
      filterDecay: filterDecay ?? this.filterDecay,
      filterSustain: filterSustain ?? this.filterSustain,
      filterRelease: filterRelease ?? this.filterRelease,
      filterKeyTrack: filterKeyTrack ?? this.filterKeyTrack,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
    );
  }

  @override
  PhaseModSynthDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'pmOp1Ratio' => copyWith(pmOp1Ratio: value),
      'pmOp1Fine' => copyWith(pmOp1Fine: value),
      'pmOp1Level' => copyWith(pmOp1Level: value),
      'pmOp1Wave' => copyWith(pmOp1Wave: value),
      'pmOp1Attack' => copyWith(pmOp1Attack: value),
      'pmOp1Decay' => copyWith(pmOp1Decay: value),
      'pmOp1Sustain' => copyWith(pmOp1Sustain: value),
      'pmOp1Release' => copyWith(pmOp1Release: value),
      'pmOp1VelSense' => copyWith(pmOp1VelSense: value),
      'pmOp1KeyTrack' => copyWith(pmOp1KeyTrack: value),
      'pmOp2Ratio' => copyWith(pmOp2Ratio: value),
      'pmOp2Fine' => copyWith(pmOp2Fine: value),
      'pmOp2Level' => copyWith(pmOp2Level: value),
      'pmOp2Wave' => copyWith(pmOp2Wave: value),
      'pmOp2Attack' => copyWith(pmOp2Attack: value),
      'pmOp2Decay' => copyWith(pmOp2Decay: value),
      'pmOp2Sustain' => copyWith(pmOp2Sustain: value),
      'pmOp2Release' => copyWith(pmOp2Release: value),
      'pmOp2VelSense' => copyWith(pmOp2VelSense: value),
      'pmOp2KeyTrack' => copyWith(pmOp2KeyTrack: value),
      'pmOp3Ratio' => copyWith(pmOp3Ratio: value),
      'pmOp3Fine' => copyWith(pmOp3Fine: value),
      'pmOp3Level' => copyWith(pmOp3Level: value),
      'pmOp3Wave' => copyWith(pmOp3Wave: value),
      'pmOp3Attack' => copyWith(pmOp3Attack: value),
      'pmOp3Decay' => copyWith(pmOp3Decay: value),
      'pmOp3Sustain' => copyWith(pmOp3Sustain: value),
      'pmOp3Release' => copyWith(pmOp3Release: value),
      'pmOp3VelSense' => copyWith(pmOp3VelSense: value),
      'pmOp3KeyTrack' => copyWith(pmOp3KeyTrack: value),
      'pmOp4Ratio' => copyWith(pmOp4Ratio: value),
      'pmOp4Fine' => copyWith(pmOp4Fine: value),
      'pmOp4Level' => copyWith(pmOp4Level: value),
      'pmOp4Wave' => copyWith(pmOp4Wave: value),
      'pmOp4Attack' => copyWith(pmOp4Attack: value),
      'pmOp4Decay' => copyWith(pmOp4Decay: value),
      'pmOp4Sustain' => copyWith(pmOp4Sustain: value),
      'pmOp4Release' => copyWith(pmOp4Release: value),
      'pmOp4VelSense' => copyWith(pmOp4VelSense: value),
      'pmOp4KeyTrack' => copyWith(pmOp4KeyTrack: value),
      'pmAlgoIndex' => copyWith(pmAlgoIndex: value.round()),
      'pmFeedback' => copyWith(pmFeedback: value),
      'pmUnisonVoices' => copyWith(pmUnisonVoices: value),
      'pmUnisonDetune' => copyWith(pmUnisonDetune: value),
      'pmGlide' => copyWith(pmGlide: value),
      'pmMono' => copyWith(pmMono: value),
      'pmLegato' => copyWith(pmLegato: value),
      'pmMasterVol' => copyWith(pmMasterVol: value),
      'pmLfoRate' => copyWith(pmLfoRate: value),
      'pmLfoShape' => copyWith(pmLfoShape: value),
      'pmLfoAmount' => copyWith(pmLfoAmount: value),
      'pmLfoDest' => copyWith(pmLfoDest: value.round()),
      'pmVibratoDepth' => copyWith(pmVibratoDepth: value),
      'pmVibratoRate' => copyWith(pmVibratoRate: value),
      'filterCutoff' => copyWith(filterCutoff: value),
      'filterQ' => copyWith(filterQ: value),
      'filterMode' => copyWith(filterMode: value.round().clamp(0, 5)),
      'filterEnvAmount' => copyWith(filterEnvAmount: value),
      'filterAttack' => copyWith(filterAttack: value),
      'filterDecay' => copyWith(filterDecay: value),
      'filterSustain' => copyWith(filterSustain: value),
      'filterRelease' => copyWith(filterRelease: value),
      'filterKeyTrack' => copyWith(filterKeyTrack: value),
      'attack' => copyWith(attack: value),
      'decay' => copyWith(decay: value),
      'sustain' => copyWith(sustain: value),
      'release' => copyWith(release: value),
      _ => this,
    };
  }
}