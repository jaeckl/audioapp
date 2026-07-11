/// Engine project snapshot from C++.
library;

export 'clip_snapshots.dart';
export 'timeline_clip.dart';
export 'device_snapshot.dart';

import 'bridge_parsing.dart';
import 'clip_snapshots.dart';
import 'device_snapshot.dart';
import 'live_meters_dto.dart';

part 'master_track_snapshot.dart';
part 'track_freeze_snapshot.dart';
part 'track_snapshot.dart';
part 'sample_library_entry_snapshot.dart';
part 'lfo_snapshot.dart';
part 'modulation_edge_snapshot.dart';

part 'project_snapshot_track_snapshot_devices.dart';

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
    final loopRegionStart = readEngineDouble(
      snapshot['loopRegionStartBeat'],
      defaultValue: 0.0,
    );
    final loopRegionEnd = readEngineDouble(
      snapshot['loopRegionEndBeat'],
      defaultValue: 16.0,
    );
    final automationClipsList =
        automationRaw != null ? automationRaw.map((c) => AutomationClipSnapshot.fromMap(c as Map<dynamic, dynamic>)).toList() : <AutomationClipSnapshot>[];
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
      samples: samplesRaw.map((s) => SampleLibraryEntrySnapshot.fromMap(s as Map<dynamic, dynamic>)).toList(),
      tracks: tracksRaw
          .map((t) => TrackSnapshot.fromMap(
                t as Map<dynamic, dynamic>,
                projectAutomationClips: automationClipsList,
              ))
          .toList(),
      lfos: lfosRaw.map((l) => LfoSnapshot.fromMap(l as Map<dynamic, dynamic>)).toList(),
      modEdges: modEdgesRaw.map((e) => ModulationEdgeSnapshot.fromMap(e as Map<dynamic, dynamic>)).toList(),
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
    DeviceSnapshot? findInDevices(Iterable<DeviceSnapshot> devices) {
      for (final device in devices) {
        if (device.id == deviceId) return device;
        if (device is ChainDeviceSnapshot) {
          final child = findInDevices(device.devices);
          if (child != null) return child;
        }
        if (device is DrumMachineDeviceSnapshot) {
          for (final pad in device.pads) {
            final child = findInDevices(pad.devices);
            if (child != null) return child;
          }
        }
        // Recurse into virtual FX sub-strips
        if (device.audioFxDevices.isNotEmpty) {
          final child = findInDevices(device.audioFxDevices);
          if (child != null) return child;
        }
        if (device.noteFxDevices.isNotEmpty) {
          final child = findInDevices(device.noteFxDevices);
          if (child != null) return child;
        }
      }
      return null;
    }

    for (final track in tracks) {
      final device = findInDevices(track.devices);
      if (device != null) return device;
    }
    return null;
  }

  /// Merge live dynamics meter readouts from EventChannel stream.
  ProjectSnapshot withMergedMeters(LiveMetersBatch batch) {
    final meterById = {
      for (final m in batch.meters) m.deviceId: m,
    };

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
            (track) => track.copyWith(
              devices: track.devices.map((device) {
                final reading = meterById[device.id];
                if (reading == null) return device;
                return device.copyWith(
                  meterGainReductionDb: reading.gainReductionDb,
                  meterInputLevel: reading.inputLevel,
                );
              }).toList(),
            ),
          )
          .toList(),
      lfos: lfos,
      modEdges: modEdges,
      automationClips: automationClips,
    );
  }

  /// Optimistically update mute/solo on one track.
  ProjectSnapshot withTrackMix({
    required String trackId,
    bool? muted,
    bool? soloed,
  }) {
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
          .map((track) => track.id == trackId
              ? track.copyWith(muted: muted, soloed: soloed)
              : soloed == true
                  ? track.copyWith(soloed: false)
                  : track)
          .toList(),
      lfos: lfos,
      modEdges: modEdges,
      automationClips: automationClips,
    );
  }

  /// Optimistically update a device parameter in the snapshot (no bridge round-trip).
  /// Used when the engine's setDeviceParameter command returns void (no delta/snapshot).
  ProjectSnapshot withDeviceParam(String deviceId, String paramId, double value) {
    DeviceSnapshot updateDevice(DeviceSnapshot device) {
      if (device.id == deviceId) {
        return device.withParameter(paramId, value);
      }
      if (device is ChainDeviceSnapshot) {
        return device.copyWith(
          devices: device.devices.map(updateDevice).toList(growable: false),
        );
      }
      if (device is DrumMachineDeviceSnapshot) {
        return device.copyWith(
          pads: device.pads
              .map(
                (pad) => DrumPadSnapshot(
                  note: pad.note,
                  name: pad.name,
                  gain: pad.gain,
                  pan: pad.pan,
                  muted: pad.muted,
                  solo: pad.solo,
                  chokeGroup: pad.chokeGroup,
                  devices: pad.devices.map(updateDevice).toList(growable: false),
                ),
              )
              .toList(growable: false),
        );
      }
      if (device is VirtualStripHostSnapshot) {
        return (device as VirtualStripHostSnapshot).copyWith(
          audioFxDevices: device.audioFxDevices.map(updateDevice).toList(growable: false),
          noteFxDevices: device.noteFxDevices.map(updateDevice).toList(growable: false),
        );
      }
      return device;
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
          .map((t) => t.copyWith(
                devices: t.devices.map(updateDevice).toList(growable: false),
              ))
          .toList(),
      lfos: lfos,
      modEdges: modEdges,
      automationClips: automationClips,
    );
  }
}

/// Modulator source snapshot from the engine (LFO, envelope).
/// Modulation edge linking an LFO to a device parameter.
