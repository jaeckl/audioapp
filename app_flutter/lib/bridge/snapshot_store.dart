import '../bridge/project_snapshot.dart';
import 'engine_bridge.dart';

/// Cached project snapshot that can merge incremental deltas from the engine,
/// avoiding full-snapshot serialization on every mutation.
///
/// Usage:
/// ```dart
/// final store = SnapshotStore(bridge, initial);
/// // After mutation:
/// await store.applyMutation((bridge) => bridge.setBpm(140));
/// ```
class SnapshotStore {
  SnapshotStore(this._bridge, this._cached);

  final EngineBridge _bridge;
  ProjectSnapshot _cached;

  ProjectSnapshot get snapshot => _cached;

  /// Apply a mutation that returns a delta from the engine.
  /// Falls back to full snapshot if the response has no delta.
  Future<void> applyMutation(
    Future<Map<dynamic, dynamic>> Function(EngineBridge bridge) mutation,
  ) async {
    final result = await mutation(_bridge);
    final delta = result['delta'] as Map<dynamic, dynamic>?;
    if (delta == null) {
      // Fallback: parse as full snapshot
      if (result['snapshot'] != null) {
        _cached = ProjectSnapshot.fromMap(result);
      }
      return;
    }
    _mergeDelta(delta);
  }

  /// Merge a raw delta map into the cached snapshot.
  void _mergeDelta(Map<dynamic, dynamic> delta) {
    if (delta['fullRefresh'] == true) {
      final full = delta['fullSnapshot'] as Map<dynamic, dynamic>?;
      if (full != null) {
        _cached = ProjectSnapshot.fromMap({'snapshot': full, 'ok': true});
      }
      return;
    }

    // Transport deltas
    final transport = delta['transport'] as Map<dynamic, dynamic>?;
    if (transport != null) {
      int bpm = _cached.bpm;
      bool playing = _cached.playing;
      bool loopEnabled = _cached.loopEnabled;
      double loopRegionStart = _cached.loopRegionStartBeat;
      double loopRegionEnd = _cached.loopRegionEndBeat;
      double playhead = _cached.playheadBeats;
      bool recordArmed = _cached.recordArmed;
      String selectedTrackId = _cached.selectedTrackId;

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

      _cached = ProjectSnapshot(
        protocolVersion: _cached.protocolVersion,
        bpm: bpm,
        selectedTrackId: selectedTrackId,
        playheadBeats: playhead,
        playing: playing,
        loopEnabled: loopEnabled,
        loopRegionStartBeat: loopRegionStart,
        loopRegionEndBeat: loopRegionEnd,
        recordArmed: recordArmed,
        master: _cached.master,
        samples: _cached.samples,
        tracks: _cached.tracks,
        lfos: _cached.lfos,
        modEdges: _cached.modEdges,
        automationClips: _cached.automationClips,
      );
    }

    // Track/device param deltas
    final tracks = delta['tracks'] as List<dynamic>?;
    if (tracks != null && tracks.isNotEmpty) {
      _cached = _mergeTrackDeltas(tracks, _cached);
    }

    // Modulator deltas
    final mods = delta['modulators'] as List<dynamic>?;
    if (mods != null && mods.isNotEmpty) {
      _cached = _mergeModulatorDeltas(mods, _cached);
    }
  }

  ProjectSnapshot _mergeTrackDeltas(
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
      protocolVersion: snap.protocolVersion,
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

  ProjectSnapshot _mergeModulatorDeltas(
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
      protocolVersion: snap.protocolVersion,
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