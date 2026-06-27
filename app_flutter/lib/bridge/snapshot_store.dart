import 'package:flutter/foundation.dart';

import 'engine_bridge.dart';
import 'project_snapshot.dart';

/// Cached project snapshot that can merge incremental deltas from the engine,
/// avoiding full-snapshot serialization on every mutation.
///
/// The canonical state holder for the Flutter UI. All mutations go through
/// [invokeRaw], which auto-merges deltas or falls back to full snapshots.
class SnapshotStore extends ChangeNotifier {
  SnapshotStore(this._bridge);

  final EngineBridge _bridge;
  ProjectSnapshot? _state;

  /// The current project snapshot. Null until initialized.
  ProjectSnapshot? get state => _state;

  /// Initialize with a snapshot (bootstrap).
  void replaceSnapshot(ProjectSnapshot snapshot) {
    _state = snapshot;
    notifyListeners();
  }

  /// Call a mutation via [invokeRaw], merge delta or full snapshot into state.
  Future<void> invokeRaw(String method, [Map<String, dynamic>? args]) async {
    final result = await _bridge.invokeRaw(method, args);
    final delta = result['delta'] as Map<dynamic, dynamic>?;
    if (delta != null && _state != null) {
      _state = applyDeltaToSnapshot(_state!, delta);
    } else {
      _state = ProjectSnapshot.fromMap(result);
    }
    notifyListeners();
  }

  // ── Static delta merge (pure, no store needed) ────────────────

  static ProjectSnapshot applyDeltaToSnapshot(
    ProjectSnapshot snap,
    Map<dynamic, dynamic> delta,
  ) {
    if (delta['fullRefresh'] == true) {
      final full = delta['fullSnapshot'] as Map<dynamic, dynamic>?;
      if (full != null) {
        return ProjectSnapshot.fromMap({'snapshot': full, 'ok': true});
      }
      return snap;
    }

    final transport = delta['transport'] as Map<dynamic, dynamic>?;
    ProjectSnapshot result = snap;
    if (transport != null) {
      int bpm = snap.bpm;
      bool playing = snap.playing;
      bool loopEnabled = snap.loopEnabled;
      double loopRegionStart = snap.loopRegionStartBeat;
      double loopRegionEnd = snap.loopRegionEndBeat;
      double playhead = snap.playheadBeats;
      bool recordArmed = snap.recordArmed;
      String selectedTrackId = snap.selectedTrackId;

      if (transport['bpmChanged'] == true) {
        bpm = (transport['newBpm'] as num).toInt();
      }
      if (transport['playingChanged'] == true) {
        playing = transport['newPlaying'] as bool;
      }
      if (transport['loopEnabledChanged'] == true) {
        loopEnabled = transport['newLoopEnabled'] as bool;
      }
      if (transport['loopRegionStartChanged'] == true) {
        loopRegionStart = (transport['newLoopRegionStart'] as num).toDouble();
      }
      if (transport['loopRegionEndChanged'] == true) {
        loopRegionEnd = (transport['newLoopRegionEnd'] as num).toDouble();
      }
      if (transport['playheadChanged'] == true) {
        playhead = (transport['newPlayhead'] as num).toDouble();
      }
      if (transport['recordArmedChanged'] == true) {
        recordArmed = transport['newRecordArmed'] as bool;
      }
      if (transport['trackSelectedChanged'] == true) {
        selectedTrackId = transport['newSelectedTrackId'] as String;
      }

      result = ProjectSnapshot(
        bpm: bpm,
        selectedTrackId: selectedTrackId,
        playheadBeats: playhead,
        playing: playing,
        loopEnabled: loopEnabled,
        loopRegionStartBeat: loopRegionStart,
        loopRegionEndBeat: loopRegionEnd,
        recordArmed: recordArmed,
        master: snap.master,
        samples: snap.samples,
        tracks: snap.tracks,
        lfos: snap.lfos,
        modEdges: snap.modEdges,
        automationClips: snap.automationClips,
      );
    }

    final tracks = delta['tracks'] as List<dynamic>?;
    if (tracks != null && tracks.isNotEmpty) {
      result = _mergeTrackDeltas(tracks, result);
    }

    final mods = delta['modulators'] as List<dynamic>?;
    if (mods != null && mods.isNotEmpty) {
      result = _mergeModulatorDeltas(mods, result);
    }

    return result;
  }

  static ProjectSnapshot _mergeTrackDeltas(
    List<dynamic> trackDeltas,
    ProjectSnapshot snap,
  ) {
    final newTracks = snap.tracks.map((track) {
      final match = trackDeltas.cast<Map<dynamic, dynamic>>().firstWhere(
        (td) => td['trackId'] == track.id,
        orElse: () => <dynamic, dynamic>{},
      );
      if (match.isEmpty) return track;

      final deviceDeltas = match['devices'] as List<dynamic>?;
      if (deviceDeltas == null || deviceDeltas.isEmpty) return track;

      return TrackSnapshot(
        id: track.id,
        name: track.name,
        devices: track.devices.map((device) {
          final devMatch =
              deviceDeltas.cast<Map<dynamic, dynamic>>().firstWhere(
            (dd) => dd['deviceId'] == device.id,
            orElse: () => <dynamic, dynamic>{},
          );
          if (devMatch.isEmpty) return device;

          final params = devMatch['params'] as List<dynamic>?;
          if (params == null || params.isEmpty) return device;

          DeviceSnapshot updated = device;
          for (final p in params.cast<Map<dynamic, dynamic>>()) {
            final paramId = p['paramId'] as String;
            final newValue = (p['newValue'] as num).toDouble();
            updated = updated.withParameter(paramId, newValue);
          }
          return updated;
        }).toList(),
        midiClips: track.midiClips,
        sampleClips: track.sampleClips,
        automationClips: track.automationClips,
      );
    }).toList();

    return ProjectSnapshot(
      bpm: snap.bpm,
      selectedTrackId: snap.selectedTrackId,
      playheadBeats: snap.playheadBeats,
      playing: snap.playing,
      loopEnabled: snap.loopEnabled,
      loopRegionStartBeat: snap.loopRegionStartBeat,
      loopRegionEndBeat: snap.loopRegionEndBeat,
      recordArmed: snap.recordArmed,
      master: snap.master,
      samples: snap.samples,
      tracks: newTracks,
      lfos: snap.lfos,
      modEdges: snap.modEdges,
      automationClips: snap.automationClips,
    );
  }

  static ProjectSnapshot _mergeModulatorDeltas(
    List<dynamic> modDeltas,
    ProjectSnapshot snap,
  ) {
    final lfos = snap.lfos.map((lfo) {
      final match = modDeltas.cast<Map<dynamic, dynamic>>().firstWhere(
        (md) => (md['lfoId'] as num).toInt() == lfo.id,
        orElse: () => <dynamic, dynamic>{},
      );
      if (match.isEmpty) return lfo;

      final params = match['params'] as List<dynamic>?;
      if (params == null || params.isEmpty) return lfo;

      LfoSnapshot updated = lfo;
      for (final p in params.cast<Map<dynamic, dynamic>>()) {
        final param = p['param'] as String;
        final newValue = (p['newValue'] as num).toDouble();
        updated = updated.applyParamUpdate(param, newValue);
      }
      return updated;
    }).toList();

    return ProjectSnapshot(
      bpm: snap.bpm,
      selectedTrackId: snap.selectedTrackId,
      playheadBeats: snap.playheadBeats,
      playing: snap.playing,
      loopEnabled: snap.loopEnabled,
      loopRegionStartBeat: snap.loopRegionStartBeat,
      loopRegionEndBeat: snap.loopRegionEndBeat,
      recordArmed: snap.recordArmed,
      master: snap.master,
      samples: snap.samples,
      tracks: snap.tracks,
      lfos: lfos,
      modEdges: snap.modEdges,
      automationClips: snap.automationClips,
    );
  }
}