/// Engine project snapshot from C++.
library;

export 'clip_snapshots.dart';
export 'timeline_clip.dart';
export 'device_snapshot.dart';

import 'bridge_parsing.dart';
import 'clip_snapshots.dart';
import 'device_snapshot.dart';

class ProjectSnapshot {
  const ProjectSnapshot({
    required this.bpm,
    required this.selectedTrackId,
    required this.playheadBeats,
    required this.playing,
    required this.loopEnabled,
    this.loopRegionStartBeat = 0,
    this.loopRegionEndBeat = 16,
    required this.recordArmed,
    required this.master,
    required this.samples,
    required this.tracks,
    this.lfos = const [],
    this.modEdges = const [],
    this.automationClips = const [],
  });

  final int bpm;
  final String selectedTrackId;
  final double playheadBeats;
  final bool playing;
  final bool loopEnabled;
  final double loopRegionStartBeat;
  final double loopRegionEndBeat;
  double get loopLengthBeats => loopRegionEndBeat - loopRegionStartBeat;
  final bool recordArmed;
  final MasterTrackSnapshot master;
  final List<SampleLibraryEntrySnapshot> samples;
  final List<TrackSnapshot> tracks;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  /// Project-global automation clips. This is the authoritative source;
  /// `TrackSnapshot.automationClips` is kept as an empty shim so existing
  /// code that iterates per-track still compiles, but new code should read
  /// from here.
  final List<AutomationClipSnapshot> automationClips;

  factory ProjectSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final snapshot = map['snapshot'] as Map<dynamic, dynamic>? ?? map;
    final tracksRaw = snapshot['tracks'] as List<dynamic>? ?? [];
    final samplesRaw = snapshot['samples'] as List<dynamic>? ?? [];
    final lfosRaw = snapshot['lfos'] as List<dynamic>? ?? [];
    final modEdgesRaw = snapshot['modEdges'] as List<dynamic>? ?? [];
    // Prefer the new top-level array; fall back to per-track if a legacy
    // engine (or test mock) only emits the nested form.
    final automationRaw = snapshot['automationClips'] as List<dynamic>?;
    final loopRegionEndRaw = snapshot['loopRegionEndBeat'];
    final loopRegionStart = readEngineDouble(
      snapshot['loopRegionStartBeat'],
      defaultValue: 0.0,
    );
    final loopRegionEnd = loopRegionEndRaw != null
        ? readEngineDouble(loopRegionEndRaw, defaultValue: 16.0)
        : readEngineDouble(snapshot['loopLengthBeats'], defaultValue: 16.0);
    final automationClipsList = automationRaw != null
        ? automationRaw
            .map((c) => AutomationClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
            .toList()
        : <AutomationClipSnapshot>[];
    return ProjectSnapshot(
      bpm: (snapshot['bpm'] as num?)?.toInt() ?? 120,
      selectedTrackId: snapshot['selectedTrackId'] as String? ?? '',
      playheadBeats: (snapshot['playheadBeats'] as num?)?.toDouble() ?? 0.0,
      playing: snapshot['playing'] == true,
      loopEnabled: readEngineBool(snapshot['loopEnabled'], defaultValue: true),
      loopRegionStartBeat: loopRegionStart,
      loopRegionEndBeat: loopRegionEnd,
      recordArmed: snapshot['recordArmed'] == true,
      master: MasterTrackSnapshot.fromMap(snapshot['master'] as Map<dynamic, dynamic>?),
      samples: samplesRaw
          .map((s) => SampleLibraryEntrySnapshot.fromMap(s as Map<dynamic, dynamic>))
          .toList(),
      tracks: tracksRaw
          .map((t) => TrackSnapshot.fromMap(
                t as Map<dynamic, dynamic>,
                projectAutomationClips: automationClipsList,
              ))
          .toList(),
      lfos: lfosRaw
          .map((l) => LfoSnapshot.fromMap(l as Map<dynamic, dynamic>))
          .toList(),
      modEdges: modEdgesRaw
          .map((e) => ModulationEdgeSnapshot.fromMap(e as Map<dynamic, dynamic>))
          .toList(),
      automationClips: automationClipsList,
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

  Iterable<AutomationClipSnapshot> get allAutomationClips sync* {
    yield* automationClips;
  }

  AutomationClipSnapshot? automationClipById(String clipId) {
    for (final clip in automationClips) {
      if (clip.id == clipId) {
        return clip;
      }
    }
    return null;
  }

  DeviceSnapshot? deviceById(String deviceId) {
    for (final track in tracks) {
      for (final device in track.devices) {
        if (device.id == deviceId) {
          return device;
        }
      }
    }
    return null;
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
      loopRegionStartBeat: loopRegionStartBeat,
      loopRegionEndBeat: loopRegionEndBeat,
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
      automationClips: automationClips,
    );
  }
}

extension TrackSnapshotDevices on TrackSnapshot {
  /// FX/instrument devices shown in the arrangement device strip (excludes track_gain).
  Iterable<DeviceSnapshot> get visibleDevices =>
      devices.where((device) => device.type != 'track_gain');

  SamplerDeviceSnapshot? get samplerDevice {
    for (final device in visibleDevices) {
      if (device is SamplerDeviceSnapshot) {
        return device;
      }
    }
    return null;
  }

  OscillatorDeviceSnapshot? get oscillatorDevice {
    for (final device in visibleDevices) {
      if (device is OscillatorDeviceSnapshot) {
        return device;
      }
    }
    return null;
  }

  SubtractiveSynthDeviceSnapshot? get subtractiveSynthDevice {
    for (final device in visibleDevices) {
      if (device is SubtractiveSynthDeviceSnapshot) {
        return device;
      }
    }
    return null;
  }

  /// GM anchor pitch for monophonic drum generators (snare = 38, etc.).
  int? get drumAnchorPitch {
    for (final device in visibleDevices) {
      switch (device.type) {
        case 'kick_generator':
          return 36;
        case 'snare_generator':
          return 38;
        case 'clap_generator':
          return 39;
        case 'cymbal_generator':
          return 42;
        case 'crash_generator':
          return 49;
      }
    }
    return null;
  }

  TrackGainDeviceSnapshot? get trackGainDevice {
    for (var i = devices.length - 1; i >= 0; i--) {
      final d = devices[i];
      if (d is TrackGainDeviceSnapshot) {
        return d;
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
  /// Per-track view of automation clips whose `homeTrackId` matches this
  /// track's id. With the move to a global store, the per-track field is
  /// populated from `ProjectSnapshot.automationClips` for backward
  /// compatibility with code that iterates tracks. The clip's `deviceId`
  /// is independent — it can point at a device on any track.
  final List<AutomationClipSnapshot> automationClips;

  factory TrackSnapshot.fromMap(
    Map<dynamic, dynamic> map, {
    List<AutomationClipSnapshot> projectAutomationClips = const [],
  }) {
    final trackId = map['id'] as String? ?? '';
    final devicesRaw = map['devices'] as List<dynamic>? ?? [];
    final clipsRaw = map['midiClips'] as List<dynamic>? ?? [];
    final sampleClipsRaw = map['sampleClips'] as List<dynamic>? ?? [];
    final perTrackAutomation = map['automationClips'] as List<dynamic>? ?? [];
    // Project-global clips. The clip's homeTrackId is the layout choice —
    // the track lane it lives in. Unassigned clips (no target yet) are
    // still laid out on the home track the user picked at create time.
    final fromGlobal = projectAutomationClips
        .where((c) => c.homeTrackId == trackId)
        .toList();
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
      automationClips: perTrackAutomation.isNotEmpty
          ? perTrackAutomation
              .map((c) => AutomationClipSnapshot.fromMap(c as Map<dynamic, dynamic>))
              .toList()
          : fromGlobal,
    );
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

/// Modulator source snapshot from the engine (LFO, envelope).
class LfoSnapshot {
  const LfoSnapshot({
    required this.id,
    this.type = 'lfo',
    this.retrigger = 0,
    this.waveform = 0,
    this.rate = 1.0,
    this.syncDivision = 0,
    this.phase = 0.0,
    this.polarity = 0,
    this.attack = 0.1,
    this.decay = 0.25,
    this.sustain = 0.7,
    this.release = 0.35,
    this.name = '',
    this.curveType = 0,
    this.hold = 0.0,
    this.delay = 0.0,
    this.attackCurve = 0.5,
    this.decayCurve = 0.5,
    this.releaseCurve = 0.5,
    this.analogMode = 0,
    this.morph = 0.0,
    this.spread = 0.5,
    this.smoothing = 0.0,
    this.sequencerSteps = 16,
    this.sequencerDirection = 0,
    this.sequencerShape = 0,
    this.stepValues = const [],
    this.curveBpPositions = const [0.0, 1.0],
    this.curveBpValues = const [0.0, 1.0],
    this.curveBpShapes = const [0, 0],
  });

  final int id;
  /// "lfo" or "envelope" — type string from engine IModulatorType::typeId().
  final String type;
  final int retrigger;
  final int waveform;
  final double rate;
  final int syncDivision;
  final double phase;
  final int polarity;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final String name;
  final int curveType;
  final double hold;
  final double delay;
  final double attackCurve;
  final double decayCurve;
  final double releaseCurve;
  final int analogMode;
  final double morph;
  final double spread;
  final double smoothing;
  final int sequencerSteps;
  final int sequencerDirection;
  final int sequencerShape;
  final List<double> stepValues;
  final List<double> curveBpPositions;
  final List<double> curveBpValues;
  final List<int> curveBpShapes;

  int get modulatorType => type == 'envelope'
      ? 1
      : type == 'random_generator'
          ? 2
          : type == 'sequencer'
              ? 3
              : type == 'curve'
                  ? 4
                  : 0;

  factory LfoSnapshot.fromMap(Map<dynamic, dynamic> map) {
    // New style: type field from IModulatorType::paramsToVar()
    final typeStr = map['type'] as String? ?? '';
    if (typeStr == 'envelope') {
      return LfoSnapshot(
        id: (map['id'] as num?)?.toInt() ?? 0,
        type: 'envelope',
        attack: (map['attack'] as num?)?.toDouble() ?? 0.08,
        decay: (map['decay'] as num?)?.toDouble() ?? 0.22,
        sustain: (map['sustain'] as num?)?.toDouble() ?? 0.65,
        release: (map['release'] as num?)?.toDouble() ?? 0.28,
        curveType: (map['curveType'] as num?)?.toInt() ?? 0,
        hold: (map['hold'] as num?)?.toDouble() ?? 0.0,
        delay: (map['delay'] as num?)?.toDouble() ?? 0.0,
        attackCurve: (map['attackCurve'] as num?)?.toDouble() ?? 0.5,
        decayCurve: (map['decayCurve'] as num?)?.toDouble() ?? 0.5,
        releaseCurve: (map['releaseCurve'] as num?)?.toDouble() ?? 0.5,
        analogMode: (map['analogMode'] as num?)?.toInt() ?? 0,
      );
    }
    if (typeStr == 'sequencer') {
      final stepCount = (map['stepCount'] as num?)?.toInt() ?? 16;
      final steps = <double>[];
      for (var i = 0; i < stepCount; i++) {
        final key = 'step_$i';
        final val = map[key] as num?;
        steps.add(val?.toDouble() ?? 0.5);
      }
      return LfoSnapshot(
        id: (map['id'] as num?)?.toInt() ?? 0,
        type: 'sequencer',
        sequencerSteps: stepCount,
        sequencerDirection: (map['direction'] as num?)?.toInt() ?? 0,
        sequencerShape: (map['shape'] as num?)?.toInt() ?? 0,
        retrigger: (map['retrigger'] as num?)?.toInt() ?? 1,
        rate: (map['rate'] as num?)?.toDouble() ?? 0.5,
        syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 3,
        polarity: (map['polarity'] as num?)?.toInt() ?? 0,
        smoothing: (map['smoothing'] as num?)?.toDouble() ?? 0.0,
        stepValues: steps,
      );
    }
    if (typeStr == 'curve') {
      final bpCount = (map['breakpointCount'] as num?)?.toInt() ?? 2;
      final positions = <double>[];
      final values = <double>[];
      final shapes = <int>[];
      for (var i = 0; i < bpCount; i++) {
        final posKey = 'bp_${i}_pos';
        final valKey = 'bp_${i}_val';
        final shapeKey = 'bp_${i}_shape';
        positions.add((map[posKey] as num?)?.toDouble() ?? (i / (bpCount - 1).clamp(1, bpCount - 1)));
        values.add((map[valKey] as num?)?.toDouble() ?? 0.0);
        shapes.add((map[shapeKey] as num?)?.toInt() ?? 0);
      }
      return LfoSnapshot(
        id: (map['id'] as num?)?.toInt() ?? 0,
        type: 'curve',
        rate: (map['rate'] as num?)?.toDouble() ?? 0.5,
        retrigger: (map['retrigger'] as num?)?.toInt() ?? 1,
        syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 3,
        polarity: (map['polarity'] as num?)?.toInt() ?? 0,
        smoothing: (map['smoothing'] as num?)?.toDouble() ?? 0.0,
        curveBpPositions: positions,
        curveBpValues: values,
        curveBpShapes: shapes,
      );
    }
    // LFO or default (fallback for old-format JSON with numeric modulatorType)
    return LfoSnapshot(
      id: (map['id'] as num?)?.toInt() ?? 0,
      type: typeStr.isNotEmpty ? typeStr : 'lfo',
      retrigger: (map['retrigger'] as num?)?.toInt() ?? 0,
      waveform: (map['waveform'] as num?)?.toInt() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 1.0,
      syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 0,
      phase: (map['phase'] as num?)?.toDouble() ?? 0.0,
      polarity: (map['polarity'] as num?)?.toInt() ?? 0,
      attack: (map['attack'] as num?)?.toDouble() ?? 0.1,
      decay: (map['decay'] as num?)?.toDouble() ?? 0.25,
      sustain: (map['sustain'] as num?)?.toDouble() ?? 0.7,
      release: (map['release'] as num?)?.toDouble() ?? 0.35,
      curveType: (map['curveType'] as num?)?.toInt() ?? 0,
      hold: (map['hold'] as num?)?.toDouble() ?? 0.0,
      delay: (map['delay'] as num?)?.toDouble() ?? 0.0,
      attackCurve: (map['attackCurve'] as num?)?.toDouble() ?? 0.5,
      decayCurve: (map['decayCurve'] as num?)?.toDouble() ?? 0.5,
      releaseCurve: (map['releaseCurve'] as num?)?.toDouble() ?? 0.5,
      analogMode: (map['analogMode'] as num?)?.toInt() ?? 0,
      morph: (map['morph'] as num?)?.toDouble() ?? 0.0,
      spread: (map['spread'] as num?)?.toDouble() ?? 0.5,
      smoothing: (map['smoothing'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static const List<String> waveformNames = [
    'Sine', 'Tri', 'Saw', 'Square', 'Ramp',
  ];

  String get waveformName => waveform >= 0 && waveform < waveformNames.length
      ? waveformNames[waveform]
      : 'Sine';

  /// Optimistic param update: maps param name → copyWith field.
  /// Returns a new [LfoSnapshot] with that field changed.
  LfoSnapshot applyParamUpdate(String param, double value) {
    switch (param) {
      case 'retrigger':    return copyWith(retrigger: value.round());
      case 'waveform':     return copyWith(waveform: value.round());
      case 'rate':         return copyWith(rate: value);
      case 'syncDivision': return copyWith(syncDivision: value.round());
      case 'phase':        return copyWith(phase: value);
      case 'polarity':     return copyWith(polarity: value.round());
      case 'attack':       return copyWith(attack: value);
      case 'decay':        return copyWith(decay: value);
      case 'sustain':      return copyWith(sustain: value);
      case 'release':      return copyWith(release: value);
      case 'curveType':    return copyWith(curveType: value.round());
      case 'hold':         return copyWith(hold: value);
      case 'delay':        return copyWith(delay: value);
      case 'attackCurve':  return copyWith(attackCurve: value);
      case 'decayCurve':   return copyWith(decayCurve: value);
      case 'releaseCurve': return copyWith(releaseCurve: value);
      case 'analogMode':   return copyWith(analogMode: value.round());
      case 'morph':        return copyWith(morph: value);
      case 'spread':        return copyWith(spread: value);
      case 'smoothing':     return copyWith(smoothing: value);
      case 'steps':         return copyWith(sequencerSteps: value.round().clamp(1, 32));
      case 'direction':     return copyWith(sequencerDirection: value.round().clamp(0, 3));
      case 'shape':         return copyWith(sequencerShape: value.round().clamp(0, 2));
      case 'breakpointCount':
        return copyWith(curveBpPositions: [for (var i = 0; i < value.round().clamp(2, 64); i++)
          i < curveBpPositions.length ? curveBpPositions[i] : (i / (value - 1))]);
      default:
        if (param.startsWith('bp_')) {
          // bp_IDX_pos, bp_IDX_val, bp_IDX_shape
          final parts = param.split('_');
          if (parts.length == 3) {
            final idx = int.tryParse(parts[1]);
            if (idx != null && idx >= 0 && idx < 64) {
              final attr = parts[2];
              if (attr == 'pos') {
                final newVals = [...curveBpPositions];
                while (newVals.length <= idx) newVals.add(0.5);
                newVals[idx] = value.clamp(0.0, 1.0);
                return copyWith(curveBpPositions: newVals);
              }
              if (attr == 'val') {
                final newVals = [...curveBpValues];
                while (newVals.length <= idx) newVals.add(0.0);
                newVals[idx] = value.clamp(-1.0, 1.0);
                return copyWith(curveBpValues: newVals);
              }
              if (attr == 'shape') {
                final newVals = [...curveBpShapes];
                while (newVals.length <= idx) newVals.add(0);
                newVals[idx] = value.round().clamp(0, 2);
                return copyWith(curveBpShapes: newVals);
              }
            }
          }
        }
        if (param.startsWith('step_')) {
          final idx = int.tryParse(param.substring(5));
          if (idx != null && idx >= 0 && idx < stepValues.length) {
            final newSteps = [...stepValues];
            newSteps[idx] = value.clamp(0.0, 1.0);
            return copyWith(stepValues: newSteps);
          }
        }
        return this;
    }
  }

  LfoSnapshot withStepValue(int index, double value) {
    final newList = List<double>.of(stepValues);
    if (index >= 0 && index < newList.length) {
      newList[index] = value.clamp(0.0, 1.0);
    }
    return copyWith(stepValues: newList);
  }

  LfoSnapshot copyWith({
    int? id,
    String? type,
    int? retrigger,
    int? waveform,
    double? rate,
    int? syncDivision,
    double? phase,
    int? polarity,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    String? name,
    int? curveType,
    double? hold,
    double? delay,
    double? attackCurve,
    double? decayCurve,
    double? releaseCurve,
    int? analogMode,
    double? morph,
    double? spread,
    double? smoothing,
    int? sequencerSteps,
    int? sequencerDirection,
    int? sequencerShape,
    List<double>? stepValues,
    List<double>? curveBpPositions,
    List<double>? curveBpValues,
    List<int>? curveBpShapes,
  }) {
    return LfoSnapshot(
      id: id ?? this.id,
      type: type ?? this.type,
      retrigger: retrigger ?? this.retrigger,
      waveform: waveform ?? this.waveform,
      rate: rate ?? this.rate,
      syncDivision: syncDivision ?? this.syncDivision,
      phase: phase ?? this.phase,
      polarity: polarity ?? this.polarity,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      name: name ?? this.name,
      curveType: curveType ?? this.curveType,
      hold: hold ?? this.hold,
      delay: delay ?? this.delay,
      attackCurve: attackCurve ?? this.attackCurve,
      decayCurve: decayCurve ?? this.decayCurve,
      releaseCurve: releaseCurve ?? this.releaseCurve,
      analogMode: analogMode ?? this.analogMode,
      morph: morph ?? this.morph,
      spread: spread ?? this.spread,
      smoothing: smoothing ?? this.smoothing,
      sequencerSteps: sequencerSteps ?? this.sequencerSteps,
      sequencerDirection: sequencerDirection ?? this.sequencerDirection,
      sequencerShape: sequencerShape ?? this.sequencerShape,
      stepValues: stepValues ?? this.stepValues,
      curveBpPositions: curveBpPositions ?? this.curveBpPositions,
      curveBpValues: curveBpValues ?? this.curveBpValues,
      curveBpShapes: curveBpShapes ?? this.curveBpShapes,
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
