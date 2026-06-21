import 'bridge_parsing.dart';

sealed class DeviceSnapshot {
  const DeviceSnapshot({
    required this.id,
    required this.type,
    required this.gain,
    required this.pan,
    required this.bypassed,
    required this.meterGainReductionDb,
    required this.meterInputLevel,
  });

  final String id;
  final String type;
  final double gain;
  final double pan;
  final bool bypassed;
  final double meterGainReductionDb;
  final double meterInputLevel;

  DeviceSnapshot withParameter(String parameterId, double value);

  DeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
  });

  factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final type = map['type'] as String? ?? '';
    return switch (type) {
      'track_gain' => TrackGainDeviceSnapshot.fromMap(map),
      'simple_oscillator' => OscillatorDeviceSnapshot.fromMap(map),
      'simple_sampler' => SamplerDeviceSnapshot.fromMap(map),
      'subtractive_synth' => SubtractiveSynthDeviceSnapshot.fromMap(map),
      'phase_mod_synth' => PhaseModSynthDeviceSnapshot.fromMap(map),
      'bass_synth' => BassSynthDeviceSnapshot.fromMap(map),
      'kick_generator' => KickGeneratorDeviceSnapshot.fromMap(map),
      'snare_generator' => SnareGeneratorDeviceSnapshot.fromMap(map),
      'clap_generator' => ClapGeneratorDeviceSnapshot.fromMap(map),
      'cymbal_generator' => CymbalGeneratorDeviceSnapshot.fromMap(map),
      'crash_generator' => CrashGeneratorDeviceSnapshot.fromMap(map),
      'gate' => GateDeviceSnapshot.fromMap(map),
      'compressor' => CompressorDeviceSnapshot.fromMap(map),
      'expander' => ExpanderDeviceSnapshot.fromMap(map),
      'limiter' => LimiterDeviceSnapshot.fromMap(map),
      'delay' => DelayDeviceSnapshot.fromMap(map),
      'reverb' => ReverbDeviceSnapshot.fromMap(map),
      'chorus' => ChorusDeviceSnapshot.fromMap(map),
      'phaser' => PhaserDeviceSnapshot.fromMap(map),
      _ => throw ArgumentError('Unknown device type: $type'),
    };
  }
}

// --- Helpers for parsing ---

bool _readBypass(dynamic value) {
  return switch (value) {
    true => true,
    false => false,
    final num n => n != 0,
    _ => false,
  };
}

double _readOscShape(
  Map<dynamic, dynamic> params,
  String shapeKey,
  String legacyWaveKey,
  double fallback,
) {
  if (params.containsKey(shapeKey)) {
    return (params[shapeKey] as num?)?.toDouble() ?? fallback;
  }
  final legacyWave = (params[legacyWaveKey] as num?)?.toInt();
  if (legacyWave != null) {
    return legacyWave / 4.0;
  }
  return fallback;
}

double _deriveOscMixFromLegacyLevels(Map<dynamic, dynamic> params) {
  if (params.containsKey('oscMix')) {
    return (params['oscMix'] as num?)?.toDouble() ?? 0.37;
  }
  final osc1Level = (params['osc1Level'] as num?)?.toDouble() ?? 0.85;
  final osc2Level = (params['osc2Level'] as num?)?.toDouble() ?? 0.5;
  final sum = osc1Level + osc2Level;
  if (sum <= 0.001) return 0.37;
  return osc2Level / sum;
}

double _readCymbalColor(Map<dynamic, dynamic> params) {
  final color = params['cymbalColor'];
  if (color is num) {
    return color.toDouble();
  }
  final metal = (params['cymbalMetal'] as num?)?.toDouble() ?? 0.55;
  final bright = (params['cymbalBrightness'] as num?)?.toDouble() ?? 0.60;
  return (metal + bright) * 0.5;
}

double _readCrashColor(Map<dynamic, dynamic> params) {
  final color = params['crashColor'];
  if (color is num) {
    return color.toDouble();
  }
  final wash = (params['crashWash'] as num?)?.toDouble() ?? 0.60;
  final bright = (params['crashBright'] as num?)?.toDouble() ?? 0.65;
  return (wash + bright) * 0.5;
}

// --- Specialized Concrete Classes ---

class TrackGainDeviceSnapshot extends DeviceSnapshot {
  const TrackGainDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  }) : super(type: 'track_gain');

  factory TrackGainDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return TrackGainDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  TrackGainDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
  }) {
    return TrackGainDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
    );
  }

  @override
  TrackGainDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      _ => this,
    };
  }
}

class OscillatorDeviceSnapshot extends DeviceSnapshot {
  const OscillatorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.frequencyHz,
  }) : super(type: 'simple_oscillator');

  final double frequencyHz;

  factory OscillatorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return OscillatorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      frequencyHz: (params['frequency'] as num?)?.toDouble() ?? 440.0,
    );
  }

  @override
  OscillatorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? frequencyHz,
  }) {
    return OscillatorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      frequencyHz: frequencyHz ?? this.frequencyHz,
    );
  }

  @override
  OscillatorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'frequency' => copyWith(frequencyHz: value),
      _ => this,
    };
  }
}

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
      bypassed: _readBypass(params['bypass']),
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
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return SubtractiveSynthDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      osc1Shape: _readOscShape(params, 'osc1Shape', 'osc1Wave', 0.5),
      osc2Shape: _readOscShape(params, 'osc2Shape', 'osc2Wave', 0.5),
      osc1Octave: (params['osc1Octave'] as num?)?.toDouble() ?? 0.5,
      osc1Semi: (params['osc1Semi'] as num?)?.toDouble() ?? 0.0,
      osc1Detune: (params['osc1Detune'] as num?)?.toDouble() ?? 0.5,
      osc2Octave: (params['osc2Octave'] as num?)?.toDouble() ?? 0.5,
      osc2Semi: (params['osc2Semi'] as num?)?.toDouble() ?? 0.0,
      osc2Detune: (params['osc2Detune'] as num?)?.toDouble() ?? 0.5,
      oscMix: (params['oscMix'] as num?)?.toDouble() ?? _deriveOscMixFromLegacyLevels(params),
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
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return PhaseModSynthDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
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

class BassSynthDeviceSnapshot extends DeviceSnapshot {
  const BassSynthDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.bassOscShape,
    required this.bassSubMix,
    required this.bassSubOctave,
    required this.bassNoise,
    required this.bassFilterResonance,
    required this.bassDrive,
    required this.bassSquash,
    required this.bassOctave,
    required this.bassVelocitySense,
    required this.filterCutoff,
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    required this.filterEnvAmount,
    required this.filterDecay,
    required this.glideMs,
  }) : super(type: 'bass_synth');

  final double bassOscShape;
  final double bassSubMix;
  final int bassSubOctave;
  final double bassNoise;
  final double bassFilterResonance;
  final double bassDrive;
  final double bassSquash;
  final int bassOctave;
  final double bassVelocitySense;
  final double filterCutoff;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double filterEnvAmount;
  final double filterDecay;
  final double glideMs;

  factory BassSynthDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return BassSynthDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      bassOscShape: (params['bassOscShape'] as num?)?.toDouble() ?? 0.3,
      bassSubMix: (params['bassSubMix'] as num?)?.toDouble() ?? 0.5,
      bassSubOctave: (params['bassSubOctave'] as num?)?.toInt() ?? 0,
      bassNoise: (params['bassNoise'] as num?)?.toDouble() ?? 0.0,
      bassFilterResonance: (params['bassFilterResonance'] as num?)?.toDouble() ?? 0.25,
      bassDrive: (params['bassDrive'] as num?)?.toDouble() ?? 0.0,
      bassSquash: (params['bassSquash'] as num?)?.toDouble() ?? 0.0,
      bassOctave: (params['bassOctave'] as num?)?.toInt() ?? 2,
      bassVelocitySense: (params['bassVelocitySense'] as num?)?.toDouble() ?? 1.0,
      filterCutoff: (params['filterCutoff'] as num?)?.toDouble() ?? 1.0,
      attack: (params['attack'] as num?)?.toDouble() ?? 0.01,
      decay: (params['decay'] as num?)?.toDouble() ?? 0.3,
      sustain: (params['sustain'] as num?)?.toDouble() ?? 0.7,
      release: (params['release'] as num?)?.toDouble() ?? 0.4,
      filterEnvAmount: (params['filterEnvAmount'] as num?)?.toDouble() ?? 0.6,
      filterDecay: (params['filterDecay'] as num?)?.toDouble() ?? 0.4,
      glideMs: (params['glideMs'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  BassSynthDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? bassOscShape,
    double? bassSubMix,
    int? bassSubOctave,
    double? bassNoise,
    double? bassFilterResonance,
    double? bassDrive,
    double? bassSquash,
    int? bassOctave,
    double? bassVelocitySense,
    double? filterCutoff,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    double? filterEnvAmount,
    double? filterDecay,
    double? glideMs,
  }) {
    return BassSynthDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      bassOscShape: bassOscShape ?? this.bassOscShape,
      bassSubMix: bassSubMix ?? this.bassSubMix,
      bassSubOctave: bassSubOctave ?? this.bassSubOctave,
      bassNoise: bassNoise ?? this.bassNoise,
      bassFilterResonance: bassFilterResonance ?? this.bassFilterResonance,
      bassDrive: bassDrive ?? this.bassDrive,
      bassSquash: bassSquash ?? this.bassSquash,
      bassOctave: bassOctave ?? this.bassOctave,
      bassVelocitySense: bassVelocitySense ?? this.bassVelocitySense,
      filterCutoff: filterCutoff ?? this.filterCutoff,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      filterEnvAmount: filterEnvAmount ?? this.filterEnvAmount,
      filterDecay: filterDecay ?? this.filterDecay,
      glideMs: glideMs ?? this.glideMs,
    );
  }

  @override
  BassSynthDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'bassOscShape' => copyWith(bassOscShape: value.clamp(0.0, 1.0)),
      'bassSubMix' => copyWith(bassSubMix: value.clamp(0.0, 1.0)),
      'bassSubOctave' => copyWith(bassSubOctave: value.round().clamp(0, 2)),
      'bassNoise' => copyWith(bassNoise: value.clamp(0.0, 1.0)),
      'bassFilterResonance' => copyWith(bassFilterResonance: value.clamp(0.0, 1.0)),
      'bassDrive' => copyWith(bassDrive: value.clamp(0.0, 1.0)),
      'bassSquash' => copyWith(bassSquash: value.clamp(0.0, 1.0)),
      'bassOctave' => copyWith(bassOctave: value.round().clamp(0, 4)),
      'bassVelocitySense' => copyWith(bassVelocitySense: value.clamp(0.0, 1.0)),
      'filterCutoff' => copyWith(filterCutoff: value),
      'attack' => copyWith(attack: value),
      'decay' => copyWith(decay: value),
      'sustain' => copyWith(sustain: value),
      'release' => copyWith(release: value),
      'filterEnvAmount' => copyWith(filterEnvAmount: value),
      'filterDecay' => copyWith(filterDecay: value),
      'glideMs' => copyWith(glideMs: value),
      _ => this,
    };
  }
}

// --- Sealed Families ---

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

class KickGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const KickGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.kickModel,
    required this.kickPitch,
    required this.kickPunch,
    required this.kickDecay,
    required this.kickClick,
    required this.kickTone,
    required this.kickVelocity,
    required this.kickKeyTrack,
  }) : super(type: 'kick_generator');

  final double kickModel;
  final double kickPitch;
  final double kickPunch;
  final double kickDecay;
  final double kickClick;
  final double kickTone;
  final double kickVelocity;
  final double kickKeyTrack;

  factory KickGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return KickGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      kickModel: (params['kickModel'] as num?)?.toDouble() ?? 0.0,
      kickPitch: (params['kickPitch'] as num?)?.toDouble() ?? 0.55,
      kickPunch: (params['kickPunch'] as num?)?.toDouble() ?? 0.60,
      kickDecay: (params['kickDecay'] as num?)?.toDouble() ?? 0.50,
      kickClick: (params['kickClick'] as num?)?.toDouble() ?? 0.35,
      kickTone: (params['kickTone'] as num?)?.toDouble() ?? 0.50,
      kickVelocity: (params['kickVelocity'] as num?)?.toDouble() ?? 1.0,
      kickKeyTrack: (params['kickKeyTrack'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  KickGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? kickModel,
    double? kickPitch,
    double? kickPunch,
    double? kickDecay,
    double? kickClick,
    double? kickTone,
    double? kickVelocity,
    double? kickKeyTrack,
  }) {
    return KickGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      kickModel: kickModel ?? this.kickModel,
      kickPitch: kickPitch ?? this.kickPitch,
      kickPunch: kickPunch ?? this.kickPunch,
      kickDecay: kickDecay ?? this.kickDecay,
      kickClick: kickClick ?? this.kickClick,
      kickTone: kickTone ?? this.kickTone,
      kickVelocity: kickVelocity ?? this.kickVelocity,
      kickKeyTrack: kickKeyTrack ?? this.kickKeyTrack,
    );
  }

  @override
  KickGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'kickModel' => copyWith(kickModel: value.clamp(0.0, 1.0)),
      'kickPitch' => copyWith(kickPitch: value.clamp(0.0, 1.0)),
      'kickPunch' => copyWith(kickPunch: value.clamp(0.0, 1.0)),
      'kickDecay' => copyWith(kickDecay: value.clamp(0.0, 1.0)),
      'kickClick' => copyWith(kickClick: value.clamp(0.0, 1.0)),
      'kickTone' => copyWith(kickTone: value.clamp(0.0, 1.0)),
      'kickVelocity' => copyWith(kickVelocity: value.clamp(0.0, 1.0)),
      'kickKeyTrack' => copyWith(kickKeyTrack: value >= 0.5 ? 1.0 : 0.0),
      _ => this,
    };
  }
}

class SnareGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const SnareGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.snareModel,
    required this.snareBody,
    required this.snareRing,
    required this.snareTune,
    required this.snareSnares,
    required this.snareSnap,
    required this.snareDecay,
    required this.snareVelocity,
  }) : super(type: 'snare_generator');

  final double snareModel;
  final double snareBody;
  final double snareRing;
  final double snareTune;
  final double snareSnares;
  final double snareSnap;
  final double snareDecay;
  final double snareVelocity;

  factory SnareGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return SnareGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      snareModel: (params['snareModel'] as num?)?.toDouble() ?? 0.0,
      snareBody: (params['snareBody'] as num?)?.toDouble() ?? 0.45,
      snareRing: (params['snareRing'] as num?)?.toDouble() ?? 0.40,
      snareTune: (params['snareTune'] as num?)?.toDouble() ?? 0.50,
      snareSnares: (params['snareSnares'] as num?)?.toDouble() ?? 0.60,
      snareSnap: (params['snareSnap'] as num?)?.toDouble() ?? 0.40,
      snareDecay: (params['snareDecay'] as num?)?.toDouble() ?? 0.50,
      snareVelocity: (params['snareVelocity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  SnareGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? snareModel,
    double? snareBody,
    double? snareRing,
    double? snareTune,
    double? snareSnares,
    double? snareSnap,
    double? snareDecay,
    double? snareVelocity,
  }) {
    return SnareGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      snareModel: snareModel ?? this.snareModel,
      snareBody: snareBody ?? this.snareBody,
      snareRing: snareRing ?? this.snareRing,
      snareTune: snareTune ?? this.snareTune,
      snareSnares: snareSnares ?? this.snareSnares,
      snareSnap: snareSnap ?? this.snareSnap,
      snareDecay: snareDecay ?? this.snareDecay,
      snareVelocity: snareVelocity ?? this.snareVelocity,
    );
  }

  @override
  SnareGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'snareModel' => copyWith(snareModel: value.clamp(0.0, 1.0)),
      'snareBody' => copyWith(snareBody: value.clamp(0.0, 1.0)),
      'snareRing' => copyWith(snareRing: value.clamp(0.0, 1.0)),
      'snareTune' => copyWith(snareTune: value.clamp(0.0, 1.0)),
      'snareSnares' => copyWith(snareSnares: value.clamp(0.0, 1.0)),
      'snareSnap' => copyWith(snareSnap: value.clamp(0.0, 1.0)),
      'snareDecay' => copyWith(snareDecay: value.clamp(0.0, 1.0)),
      'snareVelocity' => copyWith(snareVelocity: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class ClapGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const ClapGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.clapBursts,
    required this.clapSpread,
    required this.clapTone,
    required this.clapRoom,
    required this.clapDecay,
    required this.clapVelocity,
  }) : super(type: 'clap_generator');

  final double clapBursts;
  final double clapSpread;
  final double clapTone;
  final double clapRoom;
  final double clapDecay;
  final double clapVelocity;

  factory ClapGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ClapGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      clapBursts: (params['clapBursts'] as num?)?.toDouble() ?? 0.50,
      clapSpread: (params['clapSpread'] as num?)?.toDouble() ?? 0.45,
      clapTone: (params['clapTone'] as num?)?.toDouble() ?? 0.55,
      clapRoom: (params['clapRoom'] as num?)?.toDouble() ?? 0.50,
      clapDecay: (params['clapDecay'] as num?)?.toDouble() ?? 0.50,
      clapVelocity: (params['clapVelocity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  ClapGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? clapBursts,
    double? clapSpread,
    double? clapTone,
    double? clapRoom,
    double? clapDecay,
    double? clapVelocity,
  }) {
    return ClapGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      clapBursts: clapBursts ?? this.clapBursts,
      clapSpread: clapSpread ?? this.clapSpread,
      clapTone: clapTone ?? this.clapTone,
      clapRoom: clapRoom ?? this.clapRoom,
      clapDecay: clapDecay ?? this.clapDecay,
      clapVelocity: clapVelocity ?? this.clapVelocity,
    );
  }

  @override
  ClapGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'clapBursts' => copyWith(clapBursts: value.clamp(0.0, 1.0)),
      'clapSpread' => copyWith(clapSpread: value.clamp(0.0, 1.0)),
      'clapTone' => copyWith(clapTone: value.clamp(0.0, 1.0)),
      'clapRoom' => copyWith(clapRoom: value.clamp(0.0, 1.0)),
      'clapDecay' => copyWith(clapDecay: value.clamp(0.0, 1.0)),
      'clapVelocity' => copyWith(clapVelocity: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class CymbalGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const CymbalGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.cymbalModel,
    required this.cymbalColor,
    required this.cymbalDecay,
    required this.cymbalVelocity,
    required this.cymbalWidth,
  }) : super(type: 'cymbal_generator');

  final double cymbalModel;
  final double cymbalColor;
  final double cymbalDecay;
  final double cymbalVelocity;
  final double cymbalWidth;

  factory CymbalGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return CymbalGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      cymbalModel: (params['cymbalModel'] as num?)?.toDouble() ?? 0.0,
      cymbalColor: _readCymbalColor(params),
      cymbalDecay: (params['cymbalDecay'] as num?)?.toDouble() ?? 0.50,
      cymbalVelocity: (params['cymbalVelocity'] as num?)?.toDouble() ?? 1.0,
      cymbalWidth: (params['cymbalWidth'] as num?)?.toDouble() ?? 0.35,
    );
  }

  @override
  CymbalGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? cymbalModel,
    double? cymbalColor,
    double? cymbalDecay,
    double? cymbalVelocity,
    double? cymbalWidth,
  }) {
    return CymbalGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      cymbalModel: cymbalModel ?? this.cymbalModel,
      cymbalColor: cymbalColor ?? this.cymbalColor,
      cymbalDecay: cymbalDecay ?? this.cymbalDecay,
      cymbalVelocity: cymbalVelocity ?? this.cymbalVelocity,
      cymbalWidth: cymbalWidth ?? this.cymbalWidth,
    );
  }

  @override
  CymbalGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'cymbalModel' => copyWith(cymbalModel: value.clamp(0.0, 1.0)),
      'cymbalColor' => copyWith(cymbalColor: value.clamp(0.0, 1.0)),
      'cymbalDecay' => copyWith(cymbalDecay: value.clamp(0.0, 1.0)),
      'cymbalVelocity' => copyWith(cymbalVelocity: value.clamp(0.0, 1.0)),
      'cymbalWidth' => copyWith(cymbalWidth: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class CrashGeneratorDeviceSnapshot extends DrumGeneratorDeviceSnapshot {
  const CrashGeneratorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.crashModel,
    required this.crashColor,
    required this.crashSpread,
    required this.crashDecay,
    required this.crashVelocity,
  }) : super(type: 'crash_generator');

  final double crashModel;
  final double crashColor;
  final double crashSpread;
  final double crashDecay;
  final double crashVelocity;

  factory CrashGeneratorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return CrashGeneratorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      crashModel: (params['crashModel'] as num?)?.toDouble() ?? 0.0,
      crashColor: _readCrashColor(params),
      crashSpread: (params['crashSpread'] as num?)?.toDouble() ?? 0.50,
      crashDecay: (params['crashDecay'] as num?)?.toDouble() ?? 0.55,
      crashVelocity: (params['crashVelocity'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  CrashGeneratorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? crashModel,
    double? crashColor,
    double? crashSpread,
    double? crashDecay,
    double? crashVelocity,
  }) {
    return CrashGeneratorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      crashModel: crashModel ?? this.crashModel,
      crashColor: crashColor ?? this.crashColor,
      crashSpread: crashSpread ?? this.crashSpread,
      crashDecay: crashDecay ?? this.crashDecay,
      crashVelocity: crashVelocity ?? this.crashVelocity,
    );
  }

  @override
  CrashGeneratorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'crashModel' => copyWith(crashModel: value.clamp(0.0, 1.0)),
      'crashColor' => copyWith(crashColor: value.clamp(0.0, 1.0)),
      'crashSpread' => copyWith(crashSpread: value.clamp(0.0, 1.0)),
      'crashDecay' => copyWith(crashDecay: value.clamp(0.0, 1.0)),
      'crashVelocity' => copyWith(crashVelocity: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

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

class GateDeviceSnapshot extends DynamicsDeviceSnapshot {
  const GateDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.gateThreshold,
    required this.gateAttack,
    required this.gateRelease,
    required this.gateHold,
    required this.gateRange,
  }) : super(type: 'gate');

  final double gateThreshold;
  final double gateAttack;
  final double gateRelease;
  final double gateHold;
  final double gateRange;

  factory GateDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return GateDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      gateThreshold: (params['gateThreshold'] as num?)?.toDouble() ?? 0.45,
      gateAttack: (params['gateAttack'] as num?)?.toDouble() ?? 0.25,
      gateRelease: (params['gateRelease'] as num?)?.toDouble() ?? 0.50,
      gateHold: (params['gateHold'] as num?)?.toDouble() ?? 0.20,
      gateRange: (params['gateRange'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  GateDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? gateThreshold,
    double? gateAttack,
    double? gateRelease,
    double? gateHold,
    double? gateRange,
  }) {
    return GateDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      gateThreshold: gateThreshold ?? this.gateThreshold,
      gateAttack: gateAttack ?? this.gateAttack,
      gateRelease: gateRelease ?? this.gateRelease,
      gateHold: gateHold ?? this.gateHold,
      gateRange: gateRange ?? this.gateRange,
    );
  }

  @override
  GateDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'gateThreshold' => copyWith(gateThreshold: value.clamp(0.0, 1.0)),
      'gateAttack' => copyWith(gateAttack: value.clamp(0.0, 1.0)),
      'gateRelease' => copyWith(gateRelease: value.clamp(0.0, 1.0)),
      'gateHold' => copyWith(gateHold: value.clamp(0.0, 1.0)),
      'gateRange' => copyWith(gateRange: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class CompressorDeviceSnapshot extends DynamicsDeviceSnapshot {
  const CompressorDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.compThreshold,
    required this.compRatio,
    required this.compAttack,
    required this.compRelease,
    required this.compKnee,
    required this.compMakeup,
  }) : super(type: 'compressor');

  final double compThreshold;
  final double compRatio;
  final double compAttack;
  final double compRelease;
  final double compKnee;
  final double compMakeup;

  factory CompressorDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return CompressorDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      compThreshold: (params['compThreshold'] as num?)?.toDouble() ?? 0.55,
      compRatio: (params['compRatio'] as num?)?.toDouble() ?? 0.50,
      compAttack: (params['compAttack'] as num?)?.toDouble() ?? 0.20,
      compRelease: (params['compRelease'] as num?)?.toDouble() ?? 0.55,
      compKnee: (params['compKnee'] as num?)?.toDouble() ?? 0.25,
      compMakeup: (params['compMakeup'] as num?)?.toDouble() ?? 0.35,
    );
  }

  @override
  CompressorDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? compThreshold,
    double? compRatio,
    double? compAttack,
    double? compRelease,
    double? compKnee,
    double? compMakeup,
  }) {
    return CompressorDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      compThreshold: compThreshold ?? this.compThreshold,
      compRatio: compRatio ?? this.compRatio,
      compAttack: compAttack ?? this.compAttack,
      compRelease: compRelease ?? this.compRelease,
      compKnee: compKnee ?? this.compKnee,
      compMakeup: compMakeup ?? this.compMakeup,
    );
  }

  @override
  CompressorDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'compThreshold' => copyWith(compThreshold: value.clamp(0.0, 1.0)),
      'compRatio' => copyWith(compRatio: value.clamp(0.0, 1.0)),
      'compAttack' => copyWith(compAttack: value.clamp(0.0, 1.0)),
      'compRelease' => copyWith(compRelease: value.clamp(0.0, 1.0)),
      'compKnee' => copyWith(compKnee: value.clamp(0.0, 1.0)),
      'compMakeup' => copyWith(compMakeup: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class ExpanderDeviceSnapshot extends DynamicsDeviceSnapshot {
  const ExpanderDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.expandThreshold,
    required this.expandRatio,
    required this.expandAttack,
    required this.expandRelease,
    required this.expandRange,
  }) : super(type: 'expander');

  final double expandThreshold;
  final double expandRatio;
  final double expandAttack;
  final double expandRelease;
  final double expandRange;

  factory ExpanderDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ExpanderDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      expandThreshold: (params['expandThreshold'] as num?)?.toDouble() ?? 0.40,
      expandRatio: (params['expandRatio'] as num?)?.toDouble() ?? 0.45,
      expandAttack: (params['expandAttack'] as num?)?.toDouble() ?? 0.25,
      expandRelease: (params['expandRelease'] as num?)?.toDouble() ?? 0.55,
      expandRange: (params['expandRange'] as num?)?.toDouble() ?? 0.15,
    );
  }

  @override
  ExpanderDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? expandThreshold,
    double? expandRatio,
    double? expandAttack,
    double? expandRelease,
    double? expandRange,
  }) {
    return ExpanderDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      expandThreshold: expandThreshold ?? this.expandThreshold,
      expandRatio: expandRatio ?? this.expandRatio,
      expandAttack: expandAttack ?? this.expandAttack,
      expandRelease: expandRelease ?? this.expandRelease,
      expandRange: expandRange ?? this.expandRange,
    );
  }

  @override
  ExpanderDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'expandThreshold' => copyWith(expandThreshold: value.clamp(0.0, 1.0)),
      'expandRatio' => copyWith(expandRatio: value.clamp(0.0, 1.0)),
      'expandAttack' => copyWith(expandAttack: value.clamp(0.0, 1.0)),
      'expandRelease' => copyWith(expandRelease: value.clamp(0.0, 1.0)),
      'expandRange' => copyWith(expandRange: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

class LimiterDeviceSnapshot extends DynamicsDeviceSnapshot {
  const LimiterDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required super.inputGain,
    required this.limitCeiling,
    required this.limitAttack,
    required this.limitRelease,
    required this.limitKnee,
    required this.limitDrive,
    required this.limitMakeup,
  }) : super(type: 'limiter');

  final double limitCeiling;
  final double limitAttack;
  final double limitRelease;
  final double limitKnee;
  final double limitDrive;
  final double limitMakeup;

  factory LimiterDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return LimiterDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      inputGain: (params['inputGain'] as num?)?.toDouble() ?? 1.0,
      limitCeiling: (params['limitCeiling'] as num?)?.toDouble() ?? 0.85,
      limitAttack: (params['limitAttack'] as num?)?.toDouble() ?? 0.10,
      limitRelease: (params['limitRelease'] as num?)?.toDouble() ?? 0.40,
      limitKnee: (params['limitKnee'] as num?)?.toDouble() ?? 0.0,
      limitDrive: (params['limitDrive'] as num?)?.toDouble() ?? 0.0,
      limitMakeup: (params['limitMakeup'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  LimiterDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? inputGain,
    double? limitCeiling,
    double? limitAttack,
    double? limitRelease,
    double? limitKnee,
    double? limitDrive,
    double? limitMakeup,
  }) {
    return LimiterDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      inputGain: inputGain ?? this.inputGain,
      limitCeiling: limitCeiling ?? this.limitCeiling,
      limitAttack: limitAttack ?? this.limitAttack,
      limitRelease: limitRelease ?? this.limitRelease,
      limitKnee: limitKnee ?? this.limitKnee,
      limitDrive: limitDrive ?? this.limitDrive,
      limitMakeup: limitMakeup ?? this.limitMakeup,
    );
  }

  @override
  LimiterDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'inputGain' => copyWith(inputGain: value),
      'limitCeiling' => copyWith(limitCeiling: value.clamp(0.0, 1.0)),
      'limitAttack' => copyWith(limitAttack: value.clamp(0.0, 1.0)),
      'limitRelease' => copyWith(limitRelease: value.clamp(0.0, 1.0)),
      'limitKnee' => copyWith(limitKnee: value.clamp(0.0, 1.0)),
      'limitDrive' => copyWith(limitDrive: value.clamp(0.0, 1.0)),
      'limitMakeup' => copyWith(limitMakeup: value.clamp(0.0, 1.0)),
      _ => this,
    };
  }
}

sealed class EffectDeviceSnapshot extends DeviceSnapshot {
  const EffectDeviceSnapshot({
    required super.id,
    required super.type,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
  });
}

class DelayDeviceSnapshot extends EffectDeviceSnapshot {
  const DelayDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.delayTimeMs,
    required this.delayFeedback,
    required this.delayMix,
    required this.delayFilterCutoffHz,
  }) : super(type: 'delay');

  final double delayTimeMs;
  final double delayFeedback;
  final double delayMix;
  final double delayFilterCutoffHz;

  factory DelayDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DelayDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      delayTimeMs: (params['timeMs'] as num?)?.toDouble() ?? 250.0,
      delayFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.4,
      delayMix: (params['mix'] as num?)?.toDouble() ?? 0.5,
      delayFilterCutoffHz: (params['filterCutoffHz'] as num?)?.toDouble() ?? 0.5,
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
    double? delayTimeMs,
    double? delayFeedback,
    double? delayMix,
    double? delayFilterCutoffHz,
  }) {
    return DelayDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      delayTimeMs: delayTimeMs ?? this.delayTimeMs,
      delayFeedback: delayFeedback ?? this.delayFeedback,
      delayMix: delayMix ?? this.delayMix,
      delayFilterCutoffHz: delayFilterCutoffHz ?? this.delayFilterCutoffHz,
    );
  }

  @override
  DelayDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'timeMs' => copyWith(delayTimeMs: value),
      'feedback' => copyWith(delayFeedback: value),
      'mix' => copyWith(delayMix: value),
      'filterCutoffHz' => copyWith(delayFilterCutoffHz: value),
      _ => this,
    };
  }
}

class ReverbDeviceSnapshot extends EffectDeviceSnapshot {
  const ReverbDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.reverbRoomSize,
    required this.reverbDamping,
    required this.reverbWetLevel,
    required this.reverbDryLevel,
    required this.reverbWidth,
  }) : super(type: 'reverb');

  final double reverbRoomSize;
  final double reverbDamping;
  final double reverbWetLevel;
  final double reverbDryLevel;
  final double reverbWidth;

  factory ReverbDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ReverbDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      reverbRoomSize: (params['roomSize'] as num?)?.toDouble() ?? 0.5,
      reverbDamping: (params['damping'] as num?)?.toDouble() ?? 0.3,
      reverbWetLevel: (params['wetLevel'] as num?)?.toDouble() ?? 0.4,
      reverbDryLevel: (params['dryLevel'] as num?)?.toDouble() ?? 0.6,
      reverbWidth: (params['width'] as num?)?.toDouble() ?? 0.5,
    );
  }

  @override
  ReverbDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? reverbRoomSize,
    double? reverbDamping,
    double? reverbWetLevel,
    double? reverbDryLevel,
    double? reverbWidth,
  }) {
    return ReverbDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      reverbRoomSize: reverbRoomSize ?? this.reverbRoomSize,
      reverbDamping: reverbDamping ?? this.reverbDamping,
      reverbWetLevel: reverbWetLevel ?? this.reverbWetLevel,
      reverbDryLevel: reverbDryLevel ?? this.reverbDryLevel,
      reverbWidth: reverbWidth ?? this.reverbWidth,
    );
  }

  @override
  ReverbDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'roomSize' => copyWith(reverbRoomSize: value),
      'damping' => copyWith(reverbDamping: value),
      'wetLevel' => copyWith(reverbWetLevel: value),
      'dryLevel' => copyWith(reverbDryLevel: value),
      'width' => copyWith(reverbWidth: value),
      _ => this,
    };
  }
}

class ChorusDeviceSnapshot extends EffectDeviceSnapshot {
  const ChorusDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.chorusDepth,
    required this.chorusRateHz,
    required this.chorusMix,
    required this.chorusCentreDelayMs,
    required this.chorusFeedback,
  }) : super(type: 'chorus');

  final double chorusDepth;
  final double chorusRateHz;
  final double chorusMix;
  final double chorusCentreDelayMs;
  final double chorusFeedback;

  factory ChorusDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return ChorusDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      chorusDepth: (params['depth'] as num?)?.toDouble() ?? 0.3,
      chorusRateHz: (params['rateHz'] as num?)?.toDouble() ?? 0.5,
      chorusMix: (params['mix'] as num?)?.toDouble() ?? 0.4,
      chorusCentreDelayMs: (params['centreDelayMs'] as num?)?.toDouble() ?? 0.3,
      chorusFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.3,
    );
  }

  @override
  ChorusDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? chorusDepth,
    double? chorusRateHz,
    double? chorusMix,
    double? chorusCentreDelayMs,
    double? chorusFeedback,
  }) {
    return ChorusDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      chorusDepth: chorusDepth ?? this.chorusDepth,
      chorusRateHz: chorusRateHz ?? this.chorusRateHz,
      chorusMix: chorusMix ?? this.chorusMix,
      chorusCentreDelayMs: chorusCentreDelayMs ?? this.chorusCentreDelayMs,
      chorusFeedback: chorusFeedback ?? this.chorusFeedback,
    );
  }

  @override
  ChorusDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'depth' => copyWith(chorusDepth: value),
      'rateHz' => copyWith(chorusRateHz: value),
      'mix' => copyWith(chorusMix: value),
      'centreDelayMs' => copyWith(chorusCentreDelayMs: value),
      'feedback' => copyWith(chorusFeedback: value),
      _ => this,
    };
  }
}

class PhaserDeviceSnapshot extends EffectDeviceSnapshot {
  const PhaserDeviceSnapshot({
    required super.id,
    required super.gain,
    required super.pan,
    required super.bypassed,
    required super.meterGainReductionDb,
    required super.meterInputLevel,
    required this.phaserDepth,
    required this.phaserRateHz,
    required this.phaserFeedback,
    required this.phaserCentreFrequencyHz,
  }) : super(type: 'phaser');

  final double phaserDepth;
  final double phaserRateHz;
  final double phaserFeedback;
  final double phaserCentreFrequencyHz;

  factory PhaserDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return PhaserDeviceSnapshot(
      id: map['id'] as String? ?? '',
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
      bypassed: _readBypass(params['bypass']),
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
      phaserDepth: (params['depth'] as num?)?.toDouble() ?? 0.5,
      phaserRateHz: (params['rateHz'] as num?)?.toDouble() ?? 0.5,
      phaserFeedback: (params['feedback'] as num?)?.toDouble() ?? 0.3,
      phaserCentreFrequencyHz: (params['centreFrequencyHz'] as num?)?.toDouble() ?? 0.3,
    );
  }

  @override
  PhaserDeviceSnapshot copyWith({
    String? id,
    String? type,
    double? gain,
    double? pan,
    bool? bypassed,
    double? meterGainReductionDb,
    double? meterInputLevel,
    double? phaserDepth,
    double? phaserRateHz,
    double? phaserFeedback,
    double? phaserCentreFrequencyHz,
  }) {
    return PhaserDeviceSnapshot(
      id: id ?? this.id,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
      bypassed: bypassed ?? this.bypassed,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
      phaserDepth: phaserDepth ?? this.phaserDepth,
      phaserRateHz: phaserRateHz ?? this.phaserRateHz,
      phaserFeedback: phaserFeedback ?? this.phaserFeedback,
      phaserCentreFrequencyHz: phaserCentreFrequencyHz ?? this.phaserCentreFrequencyHz,
    );
  }

  @override
  PhaserDeviceSnapshot withParameter(String parameterId, double value) {
    return switch (parameterId) {
      'gain' => copyWith(gain: value),
      'pan' => copyWith(pan: value),
      'bypass' => copyWith(bypassed: value >= 0.5),
      'depth' => copyWith(phaserDepth: value),
      'rateHz' => copyWith(phaserRateHz: value),
      'feedback' => copyWith(phaserFeedback: value),
      'centreFrequencyHz' => copyWith(phaserCentreFrequencyHz: value),
      _ => this,
    };
  }
}
