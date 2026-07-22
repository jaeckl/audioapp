part of '../device_snapshot.dart';

class WavetableSynthDeviceSnapshot extends DeviceSnapshot
    implements VirtualStripHostSnapshot {
  @override
  final List<DeviceSnapshot> audioFxDevices;
  @override
  final List<DeviceSnapshot> noteFxDevices;
  const WavetableSynthDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.wavetableId,
    required this.wtPosition,
    required this.wtOctave,
    required this.wtSemitone,
    required this.wtFine,
    required this.wtUnison,
    required this.wtDetune,
    required this.wtSubLevel,
    required this.wtSubOctave,
    required this.wtNoiseLevel,
    required this.wtNoiseColor,
    required this.wtWarp,
    required this.wtWarpMode,
    required this.wtPhase,
    required this.wtPhaseRandom,
    required this.wtSubShape,
    required this.filterMode,
    required this.filterCutoff,
    required this.filterResonance,
    required this.filterEnvAmount,
    required this.filterAttack,
    required this.filterDecay,
    required this.filterSustain,
    required this.filterRelease,
    required this.filterDrive,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.wtFeedback,
    required this.wtStereoSpread,
    required this.wtGlide,
    this.audioFxDevices = const [],
    this.noteFxDevices = const [],
  }) : super(type: 'wavetable_synth');

  final String wavetableId;
  final double wtPosition;
  final double wtOctave;
  final double wtSemitone;
  final double wtFine;
  final double wtUnison;
  final double wtDetune;
  final double wtSubLevel;
  final int wtSubOctave;
  final double wtNoiseLevel;
  final double wtNoiseColor;
  final double wtWarp;
  final int wtWarpMode;
  final double wtPhase;
  final double wtPhaseRandom;
  final int wtSubShape;
  final int filterMode;
  final double filterCutoff;
  final double filterResonance;
  final double filterEnvAmount;
  final double filterAttack;
  final double filterDecay;
  final double filterSustain;
  final double filterRelease;
  final double filterDrive;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double wtFeedback;
  final double wtStereoSpread;
  final double wtGlide;

  factory WavetableSynthDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final outputPanel = map['outputPanel'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return WavetableSynthDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (outputPanel['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (outputPanel['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: readBypass(map['bypass']),
      meterGainReductionDb:
          (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      wavetableId: (params['wavetableId'] as String?) ?? 'sine_64',
      wtPosition: (params['wtPosition'] as num?)?.toDouble() ?? 0.0,
      wtOctave: (params['wtOctave'] as num?)?.toDouble() ?? 0.5,
      wtSemitone: (params['wtSemitone'] as num?)?.toDouble() ?? 0.5,
      wtFine: (params['wtFine'] as num?)?.toDouble() ?? 0.5,
      wtUnison: (params['wtUnison'] as num?)?.toDouble() ?? 0.0,
      wtDetune: (params['wtDetune'] as num?)?.toDouble() ?? 0.0,
      wtSubLevel: (params['wtSubLevel'] as num?)?.toDouble() ?? 0.0,
      wtSubOctave: (params['wtSubOctave'] as num?)?.toInt() ?? 1,
      wtNoiseLevel: (params['wtNoiseLevel'] as num?)?.toDouble() ?? 0.0,
      wtNoiseColor: (params['wtNoiseColor'] as num?)?.toDouble() ?? 0.5,
      wtWarp: (params['wtWarp'] as num?)?.toDouble() ?? 0.0,
      wtWarpMode: (params['wtWarpMode'] as num?)?.toInt() ?? 0,
      wtPhase: (params['wtPhase'] as num?)?.toDouble() ?? 0.0,
      wtPhaseRandom: (params['wtPhaseRandom'] as num?)?.toDouble() ?? 0.0,
      wtSubShape: (params['wtSubShape'] as num?)?.toInt() ?? 0,
      filterMode: (params['filterMode'] as num?)?.toInt() ?? 0,
      filterCutoff: (params['filterCutoff'] as num?)?.toDouble() ?? 1.0,
      filterResonance: (params['filterResonance'] as num?)?.toDouble() ?? 0.0,
      filterEnvAmount: (params['filterEnvAmount'] as num?)?.toDouble() ?? 0.0,
      filterAttack: (params['filterAttack'] as num?)?.toDouble() ?? 0.1,
      filterDecay: (params['filterDecay'] as num?)?.toDouble() ?? 0.3,
      filterSustain: (params['filterSustain'] as num?)?.toDouble() ?? 0.5,
      filterRelease: (params['filterRelease'] as num?)?.toDouble() ?? 0.5,
      filterDrive: (params['filterDrive'] as num?)?.toDouble() ?? 0.0,
      attack: (params['attack'] as num?)?.toDouble() ?? 0.01,
      decay: (params['decay'] as num?)?.toDouble() ?? 0.2,
      sustain: (params['sustain'] as num?)?.toDouble() ?? 0.8,
      release: (params['release'] as num?)?.toDouble() ?? 0.3,
      wtFeedback: (params['wtFeedback'] as num?)?.toDouble() ?? 0.0,
      wtStereoSpread: (params['wtStereoSpread'] as num?)?.toDouble() ?? 0.0,
      wtGlide: (params['wtGlide'] as num?)?.toDouble() ?? 0.0,
      audioFxDevices: parseDeviceList(map, 'audioFxDevices'),
      noteFxDevices: parseDeviceList(map, 'noteFxDevices'),
    );
  }

  @override
  WavetableSynthDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    String? wavetableId,
    double? wtPosition,
    double? wtOctave,
    double? wtSemitone,
    double? wtFine,
    double? wtUnison,
    double? wtDetune,
    double? wtSubLevel,
    int? wtSubOctave,
    double? wtNoiseLevel,
    double? wtNoiseColor,
    double? wtWarp,
    int? wtWarpMode,
    double? wtPhase,
    double? wtPhaseRandom,
    int? wtSubShape,
    int? filterMode,
    double? filterCutoff,
    double? filterResonance,
    double? filterEnvAmount,
    double? filterAttack,
    double? filterDecay,
    double? filterSustain,
    double? filterRelease,
    double? filterDrive,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    double? wtFeedback,
    double? wtStereoSpread,
    double? wtGlide,
    List<DeviceSnapshot>? audioFxDevices,
    List<DeviceSnapshot>? noteFxDevices,
  }) {
    return WavetableSynthDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      wavetableId: wavetableId ?? this.wavetableId,
      wtPosition: wtPosition ?? this.wtPosition,
      wtOctave: wtOctave ?? this.wtOctave,
      wtSemitone: wtSemitone ?? this.wtSemitone,
      wtFine: wtFine ?? this.wtFine,
      wtUnison: wtUnison ?? this.wtUnison,
      wtDetune: wtDetune ?? this.wtDetune,
      wtSubLevel: wtSubLevel ?? this.wtSubLevel,
      wtSubOctave: wtSubOctave ?? this.wtSubOctave,
      wtNoiseLevel: wtNoiseLevel ?? this.wtNoiseLevel,
      wtNoiseColor: wtNoiseColor ?? this.wtNoiseColor,
      wtWarp: wtWarp ?? this.wtWarp,
      wtWarpMode: wtWarpMode ?? this.wtWarpMode,
      wtPhase: wtPhase ?? this.wtPhase,
      wtPhaseRandom: wtPhaseRandom ?? this.wtPhaseRandom,
      wtSubShape: wtSubShape ?? this.wtSubShape,
      filterMode: filterMode ?? this.filterMode,
      filterCutoff: filterCutoff ?? this.filterCutoff,
      filterResonance: filterResonance ?? this.filterResonance,
      filterEnvAmount: filterEnvAmount ?? this.filterEnvAmount,
      filterAttack: filterAttack ?? this.filterAttack,
      filterDecay: filterDecay ?? this.filterDecay,
      filterSustain: filterSustain ?? this.filterSustain,
      filterRelease: filterRelease ?? this.filterRelease,
      filterDrive: filterDrive ?? this.filterDrive,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      wtFeedback: wtFeedback ?? this.wtFeedback,
      wtStereoSpread: wtStereoSpread ?? this.wtStereoSpread,
      wtGlide: wtGlide ?? this.wtGlide,
      audioFxDevices: audioFxDevices ?? this.audioFxDevices,
      noteFxDevices: noteFxDevices ?? this.noteFxDevices,
    );
  }

  @override
  WavetableSynthDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'attack' => copyWith(attack: value),
      'decay' => copyWith(decay: value),
      'sustain' => copyWith(sustain: value),
      'release' => copyWith(release: value),
      'filterCutoff' => copyWith(filterCutoff: value),
      'filterResonance' => copyWith(filterResonance: value),
      'filterMode' => copyWith(filterMode: value.round().clamp(0, 3)),
      'filterEnvAmount' => copyWith(filterEnvAmount: value),
      'filterAttack' => copyWith(filterAttack: value),
      'filterDecay' => copyWith(filterDecay: value),
      'filterSustain' => copyWith(filterSustain: value),
      'filterRelease' => copyWith(filterRelease: value),
      'filterDrive' => copyWith(filterDrive: value.clamp(0.0, 1.0)),
      'wtPosition' => copyWith(wtPosition: value.clamp(0.0, 1.0)),
      'wtOctave' => copyWith(wtOctave: value.clamp(0.0, 1.0)),
      'wtSemitone' => copyWith(wtSemitone: value.clamp(0.0, 1.0)),
      'wtFine' => copyWith(wtFine: value.clamp(0.0, 1.0)),
      'wtUnison' => copyWith(wtUnison: value.clamp(0.0, 1.0)),
      'wtDetune' => copyWith(wtDetune: value.clamp(0.0, 1.0)),
      'wtSubLevel' => copyWith(wtSubLevel: value.clamp(0.0, 1.0)),
      'wtSubOctave' => copyWith(wtSubOctave: value.round().clamp(0, 2)),
      'wtNoiseLevel' => copyWith(wtNoiseLevel: value.clamp(0.0, 1.0)),
      'wtNoiseColor' => copyWith(wtNoiseColor: value.clamp(0.0, 1.0)),
      'wtWarp' => copyWith(wtWarp: value.clamp(0.0, 1.0)),
      'wtWarpMode' => copyWith(wtWarpMode: value.round().clamp(0, 4)),
      'wtPhase' => copyWith(wtPhase: value.clamp(0.0, 1.0)),
      'wtPhaseRandom' => copyWith(wtPhaseRandom: value.clamp(0.0, 1.0)),
      'wtSubShape' => copyWith(wtSubShape: value.round().clamp(0, 2)),
      'wtFeedback' => copyWith(wtFeedback: value.clamp(0.0, 1.0)),
      'wtStereoSpread' => copyWith(wtStereoSpread: value.clamp(0.0, 1.0)),
      'wtGlide' => copyWith(wtGlide: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}
