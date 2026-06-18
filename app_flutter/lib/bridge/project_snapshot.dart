/// Engine project snapshot from C++.
library;

export 'clip_snapshots.dart';
export 'timeline_clip.dart';

import 'bridge_parsing.dart';
import 'clip_snapshots.dart';

class ProjectSnapshot {
  const ProjectSnapshot({
    required this.bpm,
    required this.selectedTrackId,
    required this.playheadBeats,
    required this.playing,
    required this.loopEnabled,
    required this.loopLengthBeats,
    required this.recordArmed,
    required this.master,
    required this.samples,
    required this.tracks,
    this.lfos = const [],
    this.modEdges = const [],
  });

  final int bpm;
  final String selectedTrackId;
  final double playheadBeats;
  final bool playing;
  final bool loopEnabled;
  final double loopLengthBeats;
  final bool recordArmed;
  final MasterTrackSnapshot master;
  final List<SampleLibraryEntrySnapshot> samples;
  final List<TrackSnapshot> tracks;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;

  factory ProjectSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final snapshot = map['snapshot'] as Map<dynamic, dynamic>? ?? map;
    final tracksRaw = snapshot['tracks'] as List<dynamic>? ?? [];
    final samplesRaw = snapshot['samples'] as List<dynamic>? ?? [];
    final lfosRaw = snapshot['lfos'] as List<dynamic>? ?? [];
    final modEdgesRaw = snapshot['modEdges'] as List<dynamic>? ?? [];
    return ProjectSnapshot(
      bpm: (snapshot['bpm'] as num?)?.toInt() ?? 120,
      selectedTrackId: snapshot['selectedTrackId'] as String? ?? '',
      playheadBeats: (snapshot['playheadBeats'] as num?)?.toDouble() ?? 0.0,
      playing: snapshot['playing'] == true,
      loopEnabled: readEngineBool(snapshot['loopEnabled'], defaultValue: true),
      loopLengthBeats: readEngineDouble(snapshot['loopLengthBeats'], defaultValue: 16.0),
      recordArmed: snapshot['recordArmed'] == true,
      master: MasterTrackSnapshot.fromMap(snapshot['master'] as Map<dynamic, dynamic>?),
      samples: samplesRaw
          .map((s) => SampleLibraryEntrySnapshot.fromMap(s as Map<dynamic, dynamic>))
          .toList(),
      tracks: tracksRaw
          .map((t) => TrackSnapshot.fromMap(t as Map<dynamic, dynamic>))
          .toList(),
      lfos: lfosRaw
          .map((l) => LfoSnapshot.fromMap(l as Map<dynamic, dynamic>))
          .toList(),
      modEdges: modEdgesRaw
          .map((e) => ModulationEdgeSnapshot.fromMap(e as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  TrackSnapshot? get selectedTrack {
    for (final track in tracks) {
      if (track.id == selectedTrackId) {
        return track;
      }
    }
    return tracks.isEmpty ? null : tracks.first;
  }

  /// Merge live dynamics meter readouts from [fresh] without replacing other state.
  ProjectSnapshot withMergedDeviceMeters(ProjectSnapshot fresh) {
    final meterByDeviceId = <String, DeviceSnapshot>{};
    for (final track in fresh.tracks) {
      for (final device in track.devices) {
        meterByDeviceId[device.id] = device;
      }
    }

    return ProjectSnapshot(
      bpm: bpm,
      selectedTrackId: selectedTrackId,
      playheadBeats: playheadBeats,
      playing: playing,
      loopEnabled: loopEnabled,
      loopLengthBeats: loopLengthBeats,
      recordArmed: recordArmed,
      master: master,
      samples: samples,
      tracks: tracks
          .map(
            (track) => TrackSnapshot(
              id: track.id,
              name: track.name,
              devices: track.devices
                  .map((device) {
                    final meters = meterByDeviceId[device.id];
                    if (meters == null) return device;
                    return device.copyWith(
                      meterGainReductionDb: meters.meterGainReductionDb,
                      meterInputLevel: meters.meterInputLevel,
                    );
                  })
                  .toList(),
              midiClips: track.midiClips,
              sampleClips: track.sampleClips,
              automationClips: track.automationClips,
            ),
          )
          .toList(),
      lfos: lfos,
      modEdges: modEdges,
    );
  }
}

extension TrackSnapshotDevices on TrackSnapshot {
  /// FX/instrument devices shown in the arrangement device strip (excludes track_gain).
  Iterable<DeviceSnapshot> get visibleDevices =>
      devices.where((device) => device.type != 'track_gain');

  DeviceSnapshot? get samplerDevice {
    for (final device in visibleDevices) {
      if (device.type == 'simple_sampler') {
        return device;
      }
    }
    return null;
  }

  DeviceSnapshot? get oscillatorDevice {
    for (final device in visibleDevices) {
      if (device.type == 'simple_oscillator') {
        return device;
      }
    }
    return null;
  }

  DeviceSnapshot? get subtractiveSynthDevice {
    for (final device in visibleDevices) {
      if (device.type == 'subtractive_synth') {
        return device;
      }
    }
    return null;
  }

  DeviceSnapshot? get trackGainDevice {
    for (var i = devices.length - 1; i >= 0; i--) {
      if (devices[i].type == 'track_gain') {
        return devices[i];
      }
    }
    return null;
  }
}

class MasterTrackSnapshot {
  const MasterTrackSnapshot({
    required this.id,
    required this.name,
    required this.gain,
  });

  final String id;
  final String name;
  final double gain;

  factory MasterTrackSnapshot.fromMap(Map<dynamic, dynamic>? map) {
    return MasterTrackSnapshot(
      id: map?['id'] as String? ?? 'master',
      name: map?['name'] as String? ?? 'Master',
      gain: (map?['gain'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class TrackSnapshot {
  const TrackSnapshot({
    required this.id,
    required this.name,
    required this.devices,
    required this.midiClips,
    required this.sampleClips,
    this.automationClips = const [],
  });

  final String id;
  final String name;
  final List<DeviceSnapshot> devices;
  final List<MidiClipSnapshot> midiClips;
  final List<SampleClipSnapshot> sampleClips;
  final List<AutomationClipSnapshot> automationClips;

  factory TrackSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final devicesRaw = map['devices'] as List<dynamic>? ?? [];
    final clipsRaw = map['midiClips'] as List<dynamic>? ?? [];
    final sampleClipsRaw = map['sampleClips'] as List<dynamic>? ?? [];
    final automationClipsRaw = map['automationClips'] as List<dynamic>? ?? [];
    return TrackSnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      devices: devicesRaw
          .map((d) => DeviceSnapshot.fromMap(d as Map<dynamic, dynamic>))
          .toList(),
      midiClips: clipsRaw
          .map((c) => MidiClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
          .toList(),
      sampleClips: sampleClipsRaw
          .map((c) => SampleClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
          .toList(),
      automationClips: automationClipsRaw
          .map((c) => AutomationClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}

class DeviceSnapshot {
  const DeviceSnapshot({
    required this.id,
    required this.type,
    required this.frequencyHz,
    required this.gain,
    required this.pan,
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
    this.regionStartSec = 0.0,
    this.regionEndSec = 0.0,
    this.bypassed = false,
    this.osc1Shape = 0.5,
    this.osc2Shape = 0.5,
    this.osc1Octave = 0.5,
    this.osc1Semi = 0.0,
    this.osc1Detune = 0.5,
    this.osc2Octave = 0.5,
    this.osc2Semi = 0.0,
    this.osc2Detune = 0.5,
    this.oscMix = 0.37,
    this.osc1Sync = 0.0,
    this.osc2Sync = 0.0,
    this.noiseLevel = 0.0,
    this.oscMixMode = 0,
    this.unisonVoices = 0.0,
    this.unisonDetune = 0.35,
    this.filterEnvAmount = 0.5,
    this.filterAttack = 0.05,
    this.filterDecay = 0.35,
    this.filterSustain = 0.4,
    this.filterRelease = 0.45,
    this.glideMs = 0.0,
    this.velocitySensitivity = 1.0,
    this.kickModel = 0.0,
    this.kickPitch = 0.55,
    this.kickPunch = 0.60,
    this.kickDecay = 0.50,
    this.kickClick = 0.35,
    this.kickTone = 0.50,
    this.kickVelocity = 1.0,
    this.snareBody = 0.55,
    this.snareTune = 0.50,
    this.snareSnares = 0.60,
    this.snareSnap = 0.40,
    this.snareDecay = 0.50,
    this.snareVelocity = 1.0,
    this.clapBursts = 0.50,
    this.clapSpread = 0.45,
    this.clapTone = 0.55,
    this.clapRoom = 0.50,
    this.clapDecay = 0.50,
    this.clapVelocity = 1.0,
    this.cymbalMetal = 0.55,
    this.cymbalBrightness = 0.60,
    this.cymbalDecay = 0.50,
    this.cymbalChoke = 0.0,
    this.cymbalVelocity = 1.0,
    this.gateThreshold = 0.45,
    this.gateAttack = 0.25,
    this.gateRelease = 0.50,
    this.gateHold = 0.20,
    this.gateRange = 0.0,
    this.compThreshold = 0.55,
    this.compRatio = 0.50,
    this.compAttack = 0.20,
    this.compRelease = 0.55,
    this.compKnee = 0.25,
    this.compMakeup = 0.35,
    this.expandThreshold = 0.40,
    this.expandRatio = 0.45,
    this.expandAttack = 0.25,
    this.expandRelease = 0.55,
    this.expandRange = 0.15,
    this.limitCeiling = 0.85,
    this.limitRelease = 0.40,
    this.limitDrive = 0.0,
    this.meterGainReductionDb = 0.0,
    this.meterInputLevel = 0.0,
  });

  final String id;
  final String type;
  final double frequencyHz;
  final double gain;
  final double pan;
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
  final bool bypassed;
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
  final double kickModel;
  final double kickPitch;
  final double kickPunch;
  final double kickDecay;
  final double kickClick;
  final double kickTone;
  final double kickVelocity;
  final double snareBody;
  final double snareTune;
  final double snareSnares;
  final double snareSnap;
  final double snareDecay;
  final double snareVelocity;
  final double clapBursts;
  final double clapSpread;
  final double clapTone;
  final double clapRoom;
  final double clapDecay;
  final double clapVelocity;
  final double cymbalMetal;
  final double cymbalBrightness;
  final double cymbalDecay;
  final double cymbalChoke;
  final double cymbalVelocity;
  final double gateThreshold;
  final double gateAttack;
  final double gateRelease;
  final double gateHold;
  final double gateRange;
  final double compThreshold;
  final double compRatio;
  final double compAttack;
  final double compRelease;
  final double compKnee;
  final double compMakeup;
  final double expandThreshold;
  final double expandRatio;
  final double expandAttack;
  final double expandRelease;
  final double expandRange;
  final double limitCeiling;
  final double limitRelease;
  final double limitDrive;
  final double meterGainReductionDb;
  final double meterInputLevel;

  factory DeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final params = map['parameters'] as Map<dynamic, dynamic>? ?? {};
    final meters = map['meters'] as Map<dynamic, dynamic>? ?? {};
    return DeviceSnapshot(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      frequencyHz: (params['frequency'] as num?)?.toDouble() ?? 440.0,
      gain: (params['gain'] as num?)?.toDouble() ?? 1.0,
      pan: (params['pan'] as num?)?.toDouble() ?? 0.5,
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
      bypassed: _readBypass(params['bypass']),
      osc1Shape: _readOscShape(params, 'osc1Shape', 'osc1Wave', 0.5),
      osc2Shape: _readOscShape(params, 'osc2Shape', 'osc2Wave', 0.5),
      osc1Octave: (params['osc1Octave'] as num?)?.toDouble() ?? 0.5,
      osc1Semi: (params['osc1Semi'] as num?)?.toDouble() ?? 0.0,
      osc1Detune: (params['osc1Detune'] as num?)?.toDouble() ?? 0.5,
      osc2Octave: (params['osc2Octave'] as num?)?.toDouble() ?? 0.5,
      osc2Semi: (params['osc2Semi'] as num?)?.toDouble() ?? 0.0,
      osc2Detune: (params['osc2Detune'] as num?)?.toDouble() ?? 0.5,
      oscMix: (params['oscMix'] as num?)?.toDouble() ??
          _deriveOscMixFromLegacyLevels(params),
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
      kickModel: (params['kickModel'] as num?)?.toDouble() ?? 0.0,
      kickPitch: (params['kickPitch'] as num?)?.toDouble() ?? 0.55,
      kickPunch: (params['kickPunch'] as num?)?.toDouble() ?? 0.60,
      kickDecay: (params['kickDecay'] as num?)?.toDouble() ?? 0.50,
      kickClick: (params['kickClick'] as num?)?.toDouble() ?? 0.35,
      kickTone: (params['kickTone'] as num?)?.toDouble() ?? 0.50,
      kickVelocity: (params['kickVelocity'] as num?)?.toDouble() ?? 1.0,
      snareBody: (params['snareBody'] as num?)?.toDouble() ?? 0.55,
      snareTune: (params['snareTune'] as num?)?.toDouble() ?? 0.50,
      snareSnares: (params['snareSnares'] as num?)?.toDouble() ?? 0.60,
      snareSnap: (params['snareSnap'] as num?)?.toDouble() ?? 0.40,
      snareDecay: (params['snareDecay'] as num?)?.toDouble() ?? 0.50,
      snareVelocity: (params['snareVelocity'] as num?)?.toDouble() ?? 1.0,
      clapBursts: (params['clapBursts'] as num?)?.toDouble() ?? 0.50,
      clapSpread: (params['clapSpread'] as num?)?.toDouble() ?? 0.45,
      clapTone: (params['clapTone'] as num?)?.toDouble() ?? 0.55,
      clapRoom: (params['clapRoom'] as num?)?.toDouble() ?? 0.50,
      clapDecay: (params['clapDecay'] as num?)?.toDouble() ?? 0.50,
      clapVelocity: (params['clapVelocity'] as num?)?.toDouble() ?? 1.0,
      cymbalMetal: (params['cymbalMetal'] as num?)?.toDouble() ?? 0.55,
      cymbalBrightness: (params['cymbalBrightness'] as num?)?.toDouble() ?? 0.60,
      cymbalDecay: (params['cymbalDecay'] as num?)?.toDouble() ?? 0.50,
      cymbalChoke: (params['cymbalChoke'] as num?)?.toDouble() ?? 0.0,
      cymbalVelocity: (params['cymbalVelocity'] as num?)?.toDouble() ?? 1.0,
      gateThreshold: (params['gateThreshold'] as num?)?.toDouble() ?? 0.45,
      gateAttack: (params['gateAttack'] as num?)?.toDouble() ?? 0.25,
      gateRelease: (params['gateRelease'] as num?)?.toDouble() ?? 0.50,
      gateHold: (params['gateHold'] as num?)?.toDouble() ?? 0.20,
      gateRange: (params['gateRange'] as num?)?.toDouble() ?? 0.0,
      compThreshold: (params['compThreshold'] as num?)?.toDouble() ?? 0.55,
      compRatio: (params['compRatio'] as num?)?.toDouble() ?? 0.50,
      compAttack: (params['compAttack'] as num?)?.toDouble() ?? 0.20,
      compRelease: (params['compRelease'] as num?)?.toDouble() ?? 0.55,
      compKnee: (params['compKnee'] as num?)?.toDouble() ?? 0.25,
      compMakeup: (params['compMakeup'] as num?)?.toDouble() ?? 0.35,
      expandThreshold: (params['expandThreshold'] as num?)?.toDouble() ?? 0.40,
      expandRatio: (params['expandRatio'] as num?)?.toDouble() ?? 0.45,
      expandAttack: (params['expandAttack'] as num?)?.toDouble() ?? 0.25,
      expandRelease: (params['expandRelease'] as num?)?.toDouble() ?? 0.55,
      expandRange: (params['expandRange'] as num?)?.toDouble() ?? 0.15,
      limitCeiling: (params['limitCeiling'] as num?)?.toDouble() ?? 0.85,
      limitRelease: (params['limitRelease'] as num?)?.toDouble() ?? 0.40,
      limitDrive: (params['limitDrive'] as num?)?.toDouble() ?? 0.0,
      meterGainReductionDb: (meters['gainReductionDb'] as num?)?.toDouble() ?? 0.0,
      meterInputLevel: (meters['inputLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static double _readOscShape(
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

  static double _deriveOscMixFromLegacyLevels(Map<dynamic, dynamic> params) {
    if (params.containsKey('oscMix')) {
      return (params['oscMix'] as num?)?.toDouble() ?? 0.37;
    }
    final osc1Level = (params['osc1Level'] as num?)?.toDouble() ?? 0.85;
    final osc2Level = (params['osc2Level'] as num?)?.toDouble() ?? 0.5;
    final sum = osc1Level + osc2Level;
    if (sum <= 0.001) return 0.37;
    return osc2Level / sum;
  }

  static bool _readBypass(dynamic value) {
    return switch (value) {
      true => true,
      false => false,
      final num n => n != 0,
      _ => false,
    };
  }

  DeviceSnapshot copyWith({
    String? id,
    String? type,
    double? frequencyHz,
    double? gain,
    double? pan,
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
    bool? bypassed,
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
    double? kickModel,
    double? kickPitch,
    double? kickPunch,
    double? kickDecay,
    double? kickClick,
    double? kickTone,
    double? kickVelocity,
    double? snareBody,
    double? snareTune,
    double? snareSnares,
    double? snareSnap,
    double? snareDecay,
    double? snareVelocity,
    double? clapBursts,
    double? clapSpread,
    double? clapTone,
    double? clapRoom,
    double? clapDecay,
    double? clapVelocity,
    double? cymbalMetal,
    double? cymbalBrightness,
    double? cymbalDecay,
    double? cymbalChoke,
    double? cymbalVelocity,
    double? gateThreshold,
    double? gateAttack,
    double? gateRelease,
    double? gateHold,
    double? gateRange,
    double? compThreshold,
    double? compRatio,
    double? compAttack,
    double? compRelease,
    double? compKnee,
    double? compMakeup,
    double? expandThreshold,
    double? expandRatio,
    double? expandAttack,
    double? expandRelease,
    double? expandRange,
    double? limitCeiling,
    double? limitRelease,
    double? limitDrive,
    double? meterGainReductionDb,
    double? meterInputLevel,
  }) {
    return DeviceSnapshot(
      id: id ?? this.id,
      type: type ?? this.type,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      gain: gain ?? this.gain,
      pan: pan ?? this.pan,
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
      bypassed: bypassed ?? this.bypassed,
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
      kickModel: kickModel ?? this.kickModel,
      kickPitch: kickPitch ?? this.kickPitch,
      kickPunch: kickPunch ?? this.kickPunch,
      kickDecay: kickDecay ?? this.kickDecay,
      kickClick: kickClick ?? this.kickClick,
      kickTone: kickTone ?? this.kickTone,
      kickVelocity: kickVelocity ?? this.kickVelocity,
      snareBody: snareBody ?? this.snareBody,
      snareTune: snareTune ?? this.snareTune,
      snareSnares: snareSnares ?? this.snareSnares,
      snareSnap: snareSnap ?? this.snareSnap,
      snareDecay: snareDecay ?? this.snareDecay,
      snareVelocity: snareVelocity ?? this.snareVelocity,
      clapBursts: clapBursts ?? this.clapBursts,
      clapSpread: clapSpread ?? this.clapSpread,
      clapTone: clapTone ?? this.clapTone,
      clapRoom: clapRoom ?? this.clapRoom,
      clapDecay: clapDecay ?? this.clapDecay,
      clapVelocity: clapVelocity ?? this.clapVelocity,
      cymbalMetal: cymbalMetal ?? this.cymbalMetal,
      cymbalBrightness: cymbalBrightness ?? this.cymbalBrightness,
      cymbalDecay: cymbalDecay ?? this.cymbalDecay,
      cymbalChoke: cymbalChoke ?? this.cymbalChoke,
      cymbalVelocity: cymbalVelocity ?? this.cymbalVelocity,
      gateThreshold: gateThreshold ?? this.gateThreshold,
      gateAttack: gateAttack ?? this.gateAttack,
      gateRelease: gateRelease ?? this.gateRelease,
      gateHold: gateHold ?? this.gateHold,
      gateRange: gateRange ?? this.gateRange,
      compThreshold: compThreshold ?? this.compThreshold,
      compRatio: compRatio ?? this.compRatio,
      compAttack: compAttack ?? this.compAttack,
      compRelease: compRelease ?? this.compRelease,
      compKnee: compKnee ?? this.compKnee,
      compMakeup: compMakeup ?? this.compMakeup,
      expandThreshold: expandThreshold ?? this.expandThreshold,
      expandRatio: expandRatio ?? this.expandRatio,
      expandAttack: expandAttack ?? this.expandAttack,
      expandRelease: expandRelease ?? this.expandRelease,
      expandRange: expandRange ?? this.expandRange,
      limitCeiling: limitCeiling ?? this.limitCeiling,
      limitRelease: limitRelease ?? this.limitRelease,
      limitDrive: limitDrive ?? this.limitDrive,
      meterGainReductionDb: meterGainReductionDb ?? this.meterGainReductionDb,
      meterInputLevel: meterInputLevel ?? this.meterInputLevel,
    );
  }

  DeviceSnapshot withParameter(String parameterId, double value) {
    switch (parameterId) {
      case 'attack':
        return copyWith(attack: value);
      case 'decay':
        return copyWith(decay: value);
      case 'sustain':
        return copyWith(sustain: value);
      case 'release':
        return copyWith(release: value);
      case 'gain':
        return copyWith(gain: value);
      case 'pan':
        return copyWith(pan: value);
      case 'filterCutoff':
        return copyWith(filterCutoff: value);
      case 'filterQ':
        return copyWith(filterQ: value);
      case 'filterMode':
        return copyWith(filterMode: value.round().clamp(0, 4));
      case 'trimStartSec':
        return copyWith(trimStartSec: value);
      case 'trimEndSec':
        return copyWith(trimEndSec: value);
      case 'regionStartSec':
        return copyWith(regionStartSec: value);
      case 'regionEndSec':
        return copyWith(regionEndSec: value);
      case 'bypass':
        return copyWith(bypassed: value >= 0.5);
      case 'osc1Shape':
        return copyWith(osc1Shape: value.clamp(0.0, 1.0));
      case 'osc2Shape':
        return copyWith(osc2Shape: value.clamp(0.0, 1.0));
      case 'osc1Octave':
        return copyWith(osc1Octave: value);
      case 'osc1Semi':
        return copyWith(osc1Semi: value);
      case 'osc1Detune':
        return copyWith(osc1Detune: value);
      case 'osc2Octave':
        return copyWith(osc2Octave: value);
      case 'osc2Semi':
        return copyWith(osc2Semi: value);
      case 'osc2Detune':
        return copyWith(osc2Detune: value);
      case 'oscMix':
        return copyWith(oscMix: value.clamp(0.0, 1.0));
      case 'osc1Sync':
        return copyWith(osc1Sync: value.clamp(0.0, 1.0));
      case 'osc2Sync':
        return copyWith(osc2Sync: value.clamp(0.0, 1.0));
      case 'noiseLevel':
        return copyWith(noiseLevel: value);
      case 'oscMixMode':
        return copyWith(oscMixMode: value.round().clamp(0, 4));
      case 'unisonVoices':
        return copyWith(unisonVoices: value);
      case 'unisonDetune':
        return copyWith(unisonDetune: value);
      case 'filterEnvAmount':
        return copyWith(filterEnvAmount: value);
      case 'filterAttack':
        return copyWith(filterAttack: value);
      case 'filterDecay':
        return copyWith(filterDecay: value);
      case 'filterSustain':
        return copyWith(filterSustain: value);
      case 'filterRelease':
        return copyWith(filterRelease: value);
      case 'glideMs':
        return copyWith(glideMs: value);
      case 'velocitySensitivity':
        return copyWith(velocitySensitivity: value);
      case 'kickModel':
        return copyWith(kickModel: value.clamp(0.0, 1.0));
      case 'kickPitch':
        return copyWith(kickPitch: value.clamp(0.0, 1.0));
      case 'kickPunch':
        return copyWith(kickPunch: value.clamp(0.0, 1.0));
      case 'kickDecay':
        return copyWith(kickDecay: value.clamp(0.0, 1.0));
      case 'kickClick':
        return copyWith(kickClick: value.clamp(0.0, 1.0));
      case 'kickTone':
        return copyWith(kickTone: value.clamp(0.0, 1.0));
      case 'kickVelocity':
        return copyWith(kickVelocity: value.clamp(0.0, 1.0));
      case 'snareBody':
        return copyWith(snareBody: value.clamp(0.0, 1.0));
      case 'snareTune':
        return copyWith(snareTune: value.clamp(0.0, 1.0));
      case 'snareSnares':
        return copyWith(snareSnares: value.clamp(0.0, 1.0));
      case 'snareSnap':
        return copyWith(snareSnap: value.clamp(0.0, 1.0));
      case 'snareDecay':
        return copyWith(snareDecay: value.clamp(0.0, 1.0));
      case 'snareVelocity':
        return copyWith(snareVelocity: value.clamp(0.0, 1.0));
      case 'clapBursts':
        return copyWith(clapBursts: value.clamp(0.0, 1.0));
      case 'clapSpread':
        return copyWith(clapSpread: value.clamp(0.0, 1.0));
      case 'clapTone':
        return copyWith(clapTone: value.clamp(0.0, 1.0));
      case 'clapRoom':
        return copyWith(clapRoom: value.clamp(0.0, 1.0));
      case 'clapDecay':
        return copyWith(clapDecay: value.clamp(0.0, 1.0));
      case 'clapVelocity':
        return copyWith(clapVelocity: value.clamp(0.0, 1.0));
      case 'cymbalMetal':
        return copyWith(cymbalMetal: value.clamp(0.0, 1.0));
      case 'cymbalBrightness':
        return copyWith(cymbalBrightness: value.clamp(0.0, 1.0));
      case 'cymbalDecay':
        return copyWith(cymbalDecay: value.clamp(0.0, 1.0));
      case 'cymbalChoke':
        return copyWith(cymbalChoke: value.clamp(0.0, 1.0));
      case 'cymbalVelocity':
        return copyWith(cymbalVelocity: value.clamp(0.0, 1.0));
      case 'gateThreshold':
        return copyWith(gateThreshold: value.clamp(0.0, 1.0));
      case 'gateAttack':
        return copyWith(gateAttack: value.clamp(0.0, 1.0));
      case 'gateRelease':
        return copyWith(gateRelease: value.clamp(0.0, 1.0));
      case 'gateHold':
        return copyWith(gateHold: value.clamp(0.0, 1.0));
      case 'gateRange':
        return copyWith(gateRange: value.clamp(0.0, 1.0));
      case 'compThreshold':
        return copyWith(compThreshold: value.clamp(0.0, 1.0));
      case 'compRatio':
        return copyWith(compRatio: value.clamp(0.0, 1.0));
      case 'compAttack':
        return copyWith(compAttack: value.clamp(0.0, 1.0));
      case 'compRelease':
        return copyWith(compRelease: value.clamp(0.0, 1.0));
      case 'compKnee':
        return copyWith(compKnee: value.clamp(0.0, 1.0));
      case 'compMakeup':
        return copyWith(compMakeup: value.clamp(0.0, 1.0));
      case 'expandThreshold':
        return copyWith(expandThreshold: value.clamp(0.0, 1.0));
      case 'expandRatio':
        return copyWith(expandRatio: value.clamp(0.0, 1.0));
      case 'expandAttack':
        return copyWith(expandAttack: value.clamp(0.0, 1.0));
      case 'expandRelease':
        return copyWith(expandRelease: value.clamp(0.0, 1.0));
      case 'expandRange':
        return copyWith(expandRange: value.clamp(0.0, 1.0));
      case 'limitCeiling':
        return copyWith(limitCeiling: value.clamp(0.0, 1.0));
      case 'limitRelease':
        return copyWith(limitRelease: value.clamp(0.0, 1.0));
      case 'limitDrive':
        return copyWith(limitDrive: value.clamp(0.0, 1.0));
      default:
        return this;
    }
  }
}

class SampleLibraryEntrySnapshot {
  const SampleLibraryEntrySnapshot({
    required this.id,
    required this.name,
    required this.source,
    required this.durationBeats,
    required this.waveformPeaks,
  });

  final String id;
  final String name;
  final String source;
  final double durationBeats;
  final List<double> waveformPeaks;

  factory SampleLibraryEntrySnapshot.fromMap(Map<dynamic, dynamic> map) {
    final peaksRaw = map['waveformPeaks'] as List<dynamic>? ?? [];
    return SampleLibraryEntrySnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      source: map['source'] as String? ?? '',
      durationBeats: (map['durationBeats'] as num?)?.toDouble() ?? 4.0,
      waveformPeaks: peaksRaw.map((p) => (p as num).toDouble()).toList(),
    );
  }
}

/// LFO source snapshot from the engine.
class LfoSnapshot {
  const LfoSnapshot({
    required this.id,
    this.waveform = 0,
    this.rate = 1.0,
    this.syncDivision = 0,
    this.phase = 0.0,
    this.name = '',
  });

  final int id;
  final int waveform; // 0=Sine, 1=Tri, 2=Saw, 3=Square, 4=Ramp
  final double rate;
  final int syncDivision; // 0=free, 1=1/1, 2=1/2, 3=1/4, 4=1/8, 5=1/16
  final double phase;
  final String name;

  factory LfoSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return LfoSnapshot(
      id: (map['id'] as num?)?.toInt() ?? 0,
      waveform: (map['waveform'] as num?)?.toInt() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 1.0,
      syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 0,
      phase: (map['phase'] as num?)?.toDouble() ?? 0.0,
      name: map['name'] as String? ?? '',
    );
  }

  static const List<String> waveformNames = [
    'Sine', 'Tri', 'Saw', 'Square', 'Ramp',
  ];

  String get waveformName => waveform >= 0 && waveform < waveformNames.length
      ? waveformNames[waveform]
      : 'Sine';

  LfoSnapshot copyWith({
    int? id,
    int? waveform,
    double? rate,
    int? syncDivision,
    double? phase,
    String? name,
  }) {
    return LfoSnapshot(
      id: id ?? this.id,
      waveform: waveform ?? this.waveform,
      rate: rate ?? this.rate,
      syncDivision: syncDivision ?? this.syncDivision,
      phase: phase ?? this.phase,
      name: name ?? this.name,
    );
  }
}

/// Modulation edge linking an LFO to a device parameter.
class ModulationEdgeSnapshot {
  const ModulationEdgeSnapshot({
    required this.lfoId,
    required this.deviceId,
    required this.paramId,
    this.amount = 0.0,
  });

  final int lfoId;
  final String deviceId;
  final String paramId;
  final double amount;

  factory ModulationEdgeSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return ModulationEdgeSnapshot(
      lfoId: (map['lfoId'] as num?)?.toInt() ?? 0,
      deviceId: map['deviceId'] as String? ?? '',
      paramId: map['paramId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  ModulationEdgeSnapshot copyWith({
    int? lfoId,
    String? deviceId,
    String? paramId,
    double? amount,
  }) {
    return ModulationEdgeSnapshot(
      lfoId: lfoId ?? this.lfoId,
      deviceId: deviceId ?? this.deviceId,
      paramId: paramId ?? this.paramId,
      amount: amount ?? this.amount,
    );
  }
}
