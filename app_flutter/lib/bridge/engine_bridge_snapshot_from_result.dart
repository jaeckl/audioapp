part of 'engine_bridge.dart';

extension EngineBridgeSnapshotfromresultOperation on EngineBridge {
ProjectSnapshot _snapshotFromResult(Map<dynamic, dynamic> result) {
    final deltaXml = result['deltaXml'] as String?;
    if (deltaXml != null && deltaXml.isNotEmpty) {
      result['delta'] = parseDeltaXml(deltaXml);
    }
    final delta = result['delta'] as Map<dynamic, dynamic>?;
    if (delta != null) {
      if (delta['fullRefresh'] == true) {
        final full = delta['fullSnapshot'] as Map<dynamic, dynamic>?;
        if (full != null) {
          return ProjectSnapshot.fromMap({'snapshot': full, 'ok': true});
        }
      } else {
        // Full state rebuilds happen through SnapshotStore.invokeRaw.
        int bpm = 120;
        bool playing = false;
        bool loopEnabled = true;
        double loopRegionStart = 0.0;
        double loopRegionEnd = 16.0;
        double playhead = 0.0;
        bool recordArmed = false;
        String selectedTrackId = '';

        final transport = delta['transport'] as Map<dynamic, dynamic>?;
        if (transport != null) {
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
            loopRegionStart =
                (transport['newLoopRegionStart'] as num).toDouble();
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
        }

        return ProjectSnapshot(
          bpm: bpm,
          selectedTrackId: selectedTrackId,
          playheadBeats: playhead,
          playing: playing,
          loopEnabled: loopEnabled,
          loopRegionStartBeat: loopRegionStart,
          loopRegionEndBeat: loopRegionEnd,
          recordArmed: recordArmed,
          master: const MasterTrackSnapshot(
              id: 'master', name: 'Master', gain: 1.0),
          samples: [],
          tracks: [],
          lfos: [],
          modEdges: [],
          automationClips: [],
        );
      }
    }
    return ProjectSnapshot.fromMap(result);
  }
}
