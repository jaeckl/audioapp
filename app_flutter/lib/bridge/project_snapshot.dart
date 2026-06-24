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

/// Modulator source snapshot from the engine (LFO, ADSR, ADR).
class LfoSnapshot {
  const LfoSnapshot({
    required this.id,
    this.modulatorType = 0,
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
  });

  final int id;
  final int modulatorType;
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

  factory LfoSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return LfoSnapshot(
      id: (map['id'] as num?)?.toInt() ?? 0,
      modulatorType: (map['modulatorType'] as num?)?.toInt() ?? 0,
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
    int? modulatorType,
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
  }) {
    return LfoSnapshot(
      id: id ?? this.id,
      modulatorType: modulatorType ?? this.modulatorType,
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
