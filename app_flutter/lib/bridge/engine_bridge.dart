import 'dart:async';

import 'package:flutter/services.dart';

import 'delta_parser.dart';
import 'live_meters_dto.dart';
import 'param_descriptor.dart';
import 'project_snapshot.dart';
import 'transport_state.dart';

class RecentProjectEntry {
  const RecentProjectEntry({
    required this.uri,
    required this.name,
    required this.openedAt,
  });

  final String uri;
  final String name;
  final DateTime openedAt;

  factory RecentProjectEntry.fromMap(Map<dynamic, dynamic> map) =>
      RecentProjectEntry(
        uri: map['uri'] as String? ?? '',
        name: map['name'] as String? ?? 'Project',
        openedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['openedAtMillis'] as num?)?.toInt() ?? 0,
        ),
      );
}

class AudioRecordingSession {
  const AudioRecordingSession({
    required this.snapshot,
    required this.sampleId,
    required this.clipId,
  });

  final ProjectSnapshot snapshot;
  final String sampleId;
  final String clipId;
}

class LiveMidiNoteEvent {
  const LiveMidiNoteEvent.noteOn({
    required this.pitch,
    required this.velocity,
  }) : allOff = false;

  const LiveMidiNoteEvent.noteOff({required this.pitch})
      : velocity = 0,
        allOff = false;

  const LiveMidiNoteEvent.allOff()
      : pitch = -1,
        velocity = 0,
        allOff = true;

  final int pitch;
  final double velocity;
  final bool allOff;
  bool get isNoteOn => !allOff && velocity > 0;
}

/// Flutter ↔ native engine bridge (MethodChannel + EventChannels).
class EngineBridge {
  EngineBridge({MethodChannel? channel, EventChannel? metersChannel})
      : _channel = channel ?? const MethodChannel('com.audioapp.daw/engine'),
        _metersChannel =
            metersChannel ?? const EventChannel('com.audioapp.daw/meters');

  final MethodChannel _channel;
  final EventChannel _metersChannel;
  final StreamController<LiveMidiNoteEvent> _noteEvents =
      StreamController<LiveMidiNoteEvent>.broadcast();

  Stream<LiveMidiNoteEvent> get noteEvents => _noteEvents.stream;

  /// Stream of live meter readings pushed from native engine (~60Hz when subscribed).
  /// Each event is a [LiveMetersBatch] containing subscribed device meters only.
  Stream<LiveMetersBatch> get meterStream =>
      _metersChannel.receiveBroadcastStream().map(
            (event) => LiveMetersBatch.fromMap(event as Map<dynamic, dynamic>),
          );

  /// Tells the engine which device IDs should publish live meter / analyzer data.
  /// Pass an empty list when the device strip is hidden or nothing is in view.
  Future<void> setMeterSubscriptions(List<String> deviceIds) async {
    await _channel.invokeMethod<void>(
      'setMeterSubscriptions',
      {'deviceIds': deviceIds},
    );
  }

  Future<String> ping() async {
    final result = await _channel.invokeMethod<String>('ping');
    return result ?? '';
  }

  Future<void> play() async {
    await _channel.invokeMethod<void>('play');
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }

  Future<ProjectSnapshot> createProject() async {
    return _invokeForSnapshot('createProject');
  }

  Future<ProjectSnapshot> getProjectSnapshot() async {
    return _invokeForSnapshot('getProjectSnapshot');
  }

  Future<TransportState> getTransportState() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('getTransportState');
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'engine_error',
        message: 'Engine command failed: getTransportState',
      );
    }
    return TransportState.fromMap(result);
  }

  Future<ProjectSnapshot> addTrack({String? name}) async {
    return _invokeForSnapshot('addTrack', {'name': name ?? ''});
  }

  Future<ProjectSnapshot> addGroupTrack({String? name}) async {
    return _invokeForSnapshot('addGroupTrack', {'name': name ?? ''});
  }

  Future<ProjectSnapshot> setTrackGroup({
    required String trackId,
    String groupTrackId = '',
  }) async {
    return _invokeForSnapshot('setTrackGroup', {
      'trackId': trackId,
      'groupTrackId': groupTrackId,
    });
  }

  Future<ProjectSnapshot> moveTrack({
    required String trackId,
    String parentGroupId = '',
    String beforeTrackId = '',
  }) async {
    return _invokeForSnapshot('moveTrack', {
      'trackId': trackId,
      'parentGroupId': parentGroupId,
      'beforeTrackId': beforeTrackId,
    });
  }

  Future<ProjectSnapshot> setTrackMuted({
    required String trackId,
    required bool muted,
  }) async {
    return _invokeForSnapshot('setTrackMuted', {
      'trackId': trackId,
      'muted': muted,
    });
  }

  Future<ProjectSnapshot> setTrackSoloed({
    required String trackId,
    required bool soloed,
  }) async {
    return _invokeForSnapshot('setTrackSoloed', {
      'trackId': trackId,
      'soloed': soloed,
    });
  }

  Future<ProjectSnapshot> freezeTrack(String trackId) async {
    return _invokeForSnapshot('freezeTrack', {'trackId': trackId});
  }

  Future<ProjectSnapshot> unfreezeTrack(String trackId) async {
    return _invokeForSnapshot('unfreezeTrack', {'trackId': trackId});
  }

  Future<ProjectSnapshot> refreshTrackFreeze(String trackId) async {
    return _invokeForSnapshot('refreshTrackFreeze', {'trackId': trackId});
  }

  Future<ProjectSnapshot> selectTrack(String trackId) async {
    return _invokeForSnapshot('selectTrack', {'trackId': trackId});
  }

  Future<ProjectSnapshot> addDeviceToTrack({
    required String trackId,
    required String deviceType,
    int? insertIndex,
  }) async {
    return _invokeForSnapshot('addDeviceToTrack', {
      'trackId': trackId,
      'deviceType': deviceType,
      if (insertIndex != null) 'insertIndex': insertIndex,
    });
  }

  Future<ProjectSnapshot> removeDeviceFromTrack({
    required String deviceId,
  }) async {
    return _invokeForSnapshot('removeDeviceFromTrack', {
      'deviceId': deviceId,
    });
  }

  Future<ProjectSnapshot> addDeviceToDrumPad({
    required String drumMachineId,
    required int note,
    required String deviceType,
    int? insertIndex,
    String? padName,
  }) =>
      _invokeForSnapshot('addDeviceToDrumPad', {
        'drumMachineId': drumMachineId,
        'note': note,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
        if (padName != null && padName.isNotEmpty) 'padName': padName,
      });

  Future<ProjectSnapshot> removeDeviceFromDrumPad({
    required String drumMachineId,
    required int note,
    required String deviceId,
  }) =>
      _invokeForSnapshot('removeDeviceFromDrumPad', {
        'drumMachineId': drumMachineId,
        'note': note,
        'deviceId': deviceId,
      });

  Future<ProjectSnapshot> addDeviceToChain({
    required String chainId,
    required String deviceType,
    int? insertIndex,
  }) =>
      _invokeForSnapshot('addDeviceToChain', {
        'chainId': chainId,
        'deviceType': deviceType,
        if (insertIndex != null) 'insertIndex': insertIndex,
      });

  Future<ProjectSnapshot> removeDeviceFromChain({
    required String chainId,
    required String deviceId,
  }) =>
      _invokeForSnapshot('removeDeviceFromChain', {
        'chainId': chainId,
        'deviceId': deviceId,
      });

  Future<String> getDevicePreset(String deviceId) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getDevicePreset',
      {'deviceId': deviceId},
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'preset_export_failed',
        message: 'Failed to export device preset',
      );
    }
    final data = result['snapshot'] as Map<dynamic, dynamic>?;
    final json = data?['presetJson'] as String?;
    if (json == null || json.isEmpty) {
      throw PlatformException(code: 'empty_device_preset');
    }
    return json;
  }

  Future<ProjectSnapshot> applyDevicePreset({
    required String deviceId,
    required String presetJson,
  }) =>
      _invokeForSnapshot('applyDevicePreset', {
        'deviceId': deviceId,
        'presetJson': presetJson,
      });

  Future<void> setDrumPadParameter({
    required String drumMachineId,
    required int note,
    required String parameterId,
    required double value,
  }) =>
      _invokeOk('setDrumPadParameter', {
        'drumMachineId': drumMachineId,
        'note': note,
        'parameterId': parameterId,
        'value': value,
      });

  Future<void> setDeviceParameter({
    required String deviceId,
    required String parameterId,
    required double value,
  }) async {
    return _invokeOk('setDeviceParameter', {
      'deviceId': deviceId,
      'parameterId': parameterId,
      'value': value,
    });
  }

  Future<void> setDeviceStringParameter({
    required String deviceId,
    required String parameterId,
    required String value,
  }) async {
    return _invokeOk('setDeviceStringParameter', {
      'deviceId': deviceId,
      'parameterId': parameterId,
      'value': value,
    });
  }

  Future<void> setMasterGain(double gain) async {
    return _invokeOk('setMasterGain', {'gain': gain});
  }

  /// Invoke and return raw result map (used for delta-aware calls).
  Future<Map<dynamic, dynamic>> invokeRaw(String method,
      [Map<String, dynamic>? args]) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(method, args);
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'engine_error',
        message: 'Engine command failed: $method',
      );
    }
    // Inline deltaXml to delta map so all callers see result['delta'].
    final deltaXml = result['deltaXml'] as String?;
    if (deltaXml != null && deltaXml.isNotEmpty) {
      result['delta'] = parseDeltaXml(deltaXml);
    }
    return result;
  }

  Future<void> setPlayheadBeats(double playheadBeats) async {
    await invokeRaw('setPlayheadBeats', {'playheadBeats': playheadBeats});
  }

  Future<ProjectSnapshot> createMidiClip({
    required String trackId,
    double startBeat = 0,
    double lengthBeats = 4,
  }) async {
    return _invokeForSnapshot('createMidiClip', {
      'trackId': trackId,
      'startBeat': startBeat,
      'lengthBeats': lengthBeats,
    });
  }

  Future<ProjectSnapshot> setMidiClipNotes({
    required String clipId,
    required List<MidiNoteSnapshot> notes,
  }) async {
    return _invokeForSnapshot('setMidiClipNotes', {
      'clipId': clipId,
      'notes': notes
          .map((n) => {
                'pitch': n.pitch,
                'startBeat': n.startBeat,
                'durationBeats': n.durationBeats,
                'velocity': n.velocity,
              })
          .toList(),
    });
  }

  Future<ProjectSnapshot> addMidiClipTake({
    required String clipId,
    required String name,
    required double startBeatOffset,
    required double lengthBeats,
    required List<MidiNoteSnapshot> notes,
  }) async {
    return _invokeForSnapshot('addMidiClipTake', {
      'clipId': clipId,
      'name': name,
      'startBeatOffset': startBeatOffset,
      'lengthBeats': lengthBeats,
      'notes': notes
          .map((n) => {
                'pitch': n.pitch,
                'startBeat': n.startBeat,
                'durationBeats': n.durationBeats,
                'velocity': n.velocity,
              })
          .toList(),
    });
  }

  Future<ProjectSnapshot> setMidiClipTakeRegionTake({
    required String clipId,
    required int regionIndex,
    required String takeId,
  }) =>
      _invokeForSnapshot('setMidiClipTakeRegionTake', {
        'clipId': clipId,
        'regionIndex': regionIndex,
        'takeId': takeId,
      });

  Future<ProjectSnapshot> setMidiClipTakeAtBeat({
    required String clipId,
    required double beat,
    required String takeId,
  }) =>
      _invokeForSnapshot('setMidiClipTakeAtBeat', {
        'clipId': clipId,
        'beat': beat,
        'takeId': takeId,
      });

  Future<ProjectSnapshot> splitMidiClipTakeRegionAtBeat({
    required String clipId,
    required double beat,
  }) =>
      _invokeForSnapshot('splitMidiClipTakeRegionAtBeat', {
        'clipId': clipId,
        'beat': beat,
      });

  Future<ProjectSnapshot> moveMidiClipTakeMarker({
    required String clipId,
    required int markerIndex,
    required double beat,
  }) =>
      _invokeForSnapshot('moveMidiClipTakeMarker', {
        'clipId': clipId,
        'markerIndex': markerIndex,
        'beat': beat,
      });

  Future<ProjectSnapshot> setMidiClipTakeMarkerMode({
    required String clipId,
    required int markerIndex,
    required bool holdPrevious,
  }) =>
      _invokeForSnapshot('setMidiClipTakeMarkerMode', {
        'clipId': clipId,
        'markerIndex': markerIndex,
        'holdPrevious': holdPrevious,
      });

  Future<ProjectSnapshot> flattenMidiComp({required String clipId}) =>
      _invokeForSnapshot('flattenMidiComp', {'clipId': clipId});

  Future<ProjectSnapshot> reopenMidiComp({required String clipId}) =>
      _invokeForSnapshot('reopenMidiComp', {'clipId': clipId});

  Future<ProjectSnapshot> deleteMidiClipTakeMarker({
    required String clipId,
    required int markerIndex,
  }) =>
      _invokeForSnapshot('deleteMidiClipTakeMarker', {
        'clipId': clipId,
        'markerIndex': markerIndex,
      });

  Future<void> setMidiClipEditorScale({
    required String clipId,
    required int rootPitchClass,
    required String scaleId,
    required bool highlight,
    required bool snapToScale,
    required String chordQuality,
  }) async {
    await _invokeOk('setMidiClipEditorScale', {
      'clipId': clipId,
      'rootPitchClass': rootPitchClass,
      'scaleId': scaleId,
      'highlight': highlight,
      'snapToScale': snapToScale,
      'chordQuality': chordQuality,
    });
  }

  Future<ProjectSnapshot> createAutomationClip({
    required String trackId,
    double startBeat = 0,
    double lengthBeats = 4,
  }) async {
    return _invokeForSnapshot('createAutomationClip', {
      'trackId': trackId,
      'startBeat': startBeat,
      'lengthBeats': lengthBeats,
    });
  }

  Future<ProjectSnapshot> assignAutomationTarget({
    required String clipId,
    required String deviceId,
    required String paramId,
  }) async {
    return _invokeForSnapshot('assignAutomationTarget', {
      'clipId': clipId,
      'deviceId': deviceId,
      'paramId': paramId,
    });
  }

  Future<ProjectSnapshot> unlinkAutomationTarget(
      {required String clipId}) async {
    return _invokeForSnapshot('unlinkAutomationTarget', {'clipId': clipId});
  }

  Future<ProjectSnapshot> setAutomationPoints({
    required String clipId,
    required List<AutomationPointSnapshot> points,
  }) async {
    return _invokeForSnapshot('setAutomationPoints', {
      'clipId': clipId,
      'points': points.map((p) => p.toMap()).toList(),
    });
  }

  Future<ProjectSnapshot> createSampleClip({
    required String trackId,
    required String sampleId,
    double startBeat = 0,
    double lengthBeats = 0,
  }) async {
    return _invokeForSnapshot('createSampleClip', {
      'trackId': trackId,
      'sampleId': sampleId,
      'startBeat': startBeat,
      'lengthBeats': lengthBeats,
    });
  }

  Future<ProjectSnapshot> moveClip({
    required String clipId,
    required String trackId,
    required double startBeat,
  }) async {
    return _invokeForSnapshot('moveClip', {
      'clipId': clipId,
      'trackId': trackId,
      'startBeat': startBeat,
    });
  }

  Future<ProjectSnapshot> setClipLength({
    required String clipId,
    required double lengthBeats,
    ClipLengthTarget target = ClipLengthTarget.arrangement,
  }) async {
    return _invokeForSnapshot('setClipLength', {
      'clipId': clipId,
      'lengthBeats': lengthBeats,
      'target': target == ClipLengthTarget.content ? 'content' : 'arrangement',
    });
  }

  Future<ProjectSnapshot> setClipLoopContent({
    required String clipId,
    required bool loopContent,
  }) async {
    return _invokeForSnapshot('setClipLoopContent', {
      'clipId': clipId,
      'loopContent': loopContent,
    });
  }

  Future<ProjectSnapshot> setSampleClipProperties({
    required String clipId,
    required double sourceStart,
    required double sourceEnd,
    required double gain,
    required double fadeIn,
    required double fadeOut,
    required double fadeInCurve,
    required double fadeOutCurve,
    required bool reversed,
  }) =>
      _invokeForSnapshot('setSampleClipProperties', {
        'clipId': clipId,
        'sourceStart': sourceStart,
        'sourceEnd': sourceEnd,
        'gain': gain,
        'fadeIn': fadeIn,
        'fadeOut': fadeOut,
        'fadeInCurve': fadeInCurve,
        'fadeOutCurve': fadeOutCurve,
        'reversed': reversed,
      });

  Future<ProjectSnapshot> setSampleClipWarp({
    required String clipId,
    required bool warpRepitch,
  }) =>
      _invokeForSnapshot('setSampleClipWarp', {
        'clipId': clipId,
        'warpRepitch': warpRepitch,
      });

  Future<ProjectSnapshot> setSampleClipSlices({
    required String clipId,
    required List<double> markers,
  }) =>
      _invokeForSnapshot('setSampleClipSlices', {
        'clipId': clipId,
        'markers': markers,
      });

  Future<ProjectSnapshot> setSampleClipTakeRegionTake({
    required String clipId,
    required int regionIndex,
    required String takeId,
  }) =>
      _invokeForSnapshot('setSampleClipTakeRegionTake', {
        'clipId': clipId,
        'regionIndex': regionIndex,
        'takeId': takeId,
      });

  Future<ProjectSnapshot> setSampleClipTakeAtBeat({
    required String clipId,
    required double beat,
    required String takeId,
  }) =>
      _invokeForSnapshot('setSampleClipTakeAtBeat', {
        'clipId': clipId,
        'beat': beat,
        'takeId': takeId,
      });

  Future<ProjectSnapshot> splitSampleClipTakeRegionAtBeat({
    required String clipId,
    required double beat,
  }) =>
      _invokeForSnapshot('splitSampleClipTakeRegionAtBeat', {
        'clipId': clipId,
        'beat': beat,
      });

  Future<ProjectSnapshot> moveSampleClipTakeMarker({
    required String clipId,
    required int markerIndex,
    required double beat,
  }) =>
      _invokeForSnapshot('moveSampleClipTakeMarker', {
        'clipId': clipId,
        'markerIndex': markerIndex,
        'beat': beat,
      });

  Future<ProjectSnapshot> deleteSampleClipTakeMarker({
    required String clipId,
    required int markerIndex,
  }) =>
      _invokeForSnapshot('deleteSampleClipTakeMarker', {
        'clipId': clipId,
        'markerIndex': markerIndex,
      });

  Future<ProjectSnapshot> exportSampleClipSlices({
    required String clipId,
    int firstNote = 36,
  }) =>
      _invokeForSnapshot('exportSampleClipSlices', {
        'clipId': clipId,
        'firstNote': firstNote,
      });

  Future<ProjectSnapshot> deleteTrack(String trackId) async {
    return _invokeForSnapshot('deleteTrack', {'trackId': trackId});
  }

  Future<ProjectSnapshot> deleteClip(String clipId) async {
    return _invokeForSnapshot('deleteClip', {'clipId': clipId});
  }

  Future<ProjectSnapshot> duplicateClip(String clipId) async {
    return _invokeForSnapshot('duplicateClip', {'clipId': clipId});
  }

  Future<void> enterPlayMode() async {
    await _invokeOk('enterPlayMode');
  }

  Future<ProjectSnapshot> setRecordArmed(bool armed) async {
    return _invokeForSnapshot('setRecordArmed', {'armed': armed});
  }

  Future<void> noteOn({required int pitch, required double velocity}) async {
    _noteEvents.add(LiveMidiNoteEvent.noteOn(
      pitch: pitch,
      velocity: velocity,
    ));
    await _invokeOk('noteOn', {'pitch': pitch, 'velocity': velocity});
  }

  Future<void> noteOff({required int pitch}) async {
    _noteEvents.add(LiveMidiNoteEvent.noteOff(pitch: pitch));
    await _invokeOk('noteOff', {'pitch': pitch});
  }

  Future<void> allNotesOff() async {
    _noteEvents.add(const LiveMidiNoteEvent.allOff());
    await _invokeOk('allNotesOff');
  }

  Future<void> setPitchBend(double bend) async {
    await _invokeOk('setPitchBend', {'bend': bend});
  }

  Future<void> setModulation(double mod) async {
    await _invokeOk('setModulation', {'mod': mod});
  }

  Future<void> clearCapture() async {
    await _invokeOk('clearCapture');
  }

  Future<ProjectSnapshot> commitCapture() async {
    return _invokeForSnapshot('commitCapture');
  }

  Future<void> beginMidiRecordingSession({
    required String trackId,
    required double startBeat,
    double quantizeStep = 0.25,
  }) async {
    await _invokeOk('beginMidiRecordingSession', {
      'trackId': trackId,
      'startBeat': startBeat,
      'quantizeStep': quantizeStep,
    });
  }

  Future<ProjectSnapshot> finishMidiRecordingSession({double? endBeat}) async {
    return _invokeForSnapshot('finishMidiRecordingSession', {
      if (endBeat != null) 'endBeat': endBeat,
    });
  }

  Future<void> cancelMidiRecordingSession() async {
    await _invokeOk('cancelMidiRecordingSession');
  }

  // ─── LFO & Modulation ─────────────────────────────────

  Future<ProjectSnapshot> createLfo({int modulatorType = 0}) async {
    return _invokeForSnapshot('createLfo', {'modulatorType': modulatorType});
  }

  Future<ProjectSnapshot> removeLfo(int lfoId) async {
    return _invokeForSnapshot('removeLfo', {'lfoId': lfoId});
  }

  Future<ProjectSnapshot> updateLfoParam({
    required int lfoId,
    required String param,
    required double value,
  }) async {
    return _invokeForSnapshot('updateLfoParam', {
      'lfoId': lfoId,
      'param': param,
      'value': value,
    });
  }

  /// Batch-update multiple LFO parameters in a single bridge call.
  /// Each entry: { 'param': String, 'value': double }.
  Future<ProjectSnapshot> batchUpdateLfoParams({
    required int lfoId,
    required List<Map<String, dynamic>> params,
  }) async {
    return _invokeForSnapshot('batchUpdateLfoParams', {
      'lfoId': lfoId,
      'params': params,
    });
  }

  Future<ProjectSnapshot> assignModulation({
    required int lfoId,
    required String deviceId,
    required String paramId,
    required double amount,
  }) async {
    return _invokeForSnapshot('assignModulation', {
      'lfoId': lfoId,
      'deviceId': deviceId,
      'paramId': paramId,
      'amount': amount,
    });
  }

  Future<ProjectSnapshot> removeModulation({
    required int lfoId,
    required String paramId,
    String? deviceId,
  }) async {
    final args = <String, dynamic>{
      'lfoId': lfoId,
      'paramId': paramId,
    };
    if (deviceId != null) {
      args['deviceId'] = deviceId;
    }
    return _invokeForSnapshot('removeModulation', args);
  }

  Future<ProjectSnapshot> applySubtractiveSynthPreset({
    required String deviceId,
    required Map<String, double> params,
    List<Map<String, dynamic>> lfos = const [],
    List<Map<String, dynamic>> mods = const [],
  }) async {
    return _invokeForSnapshot('applySubtractiveSynthPreset', {
      'deviceId': deviceId,
      'params': params,
      'lfos': lfos,
      'mods': mods,
    });
  }

  Future<void> setMetronome({
    required bool enabled,
    required double level,
    required int countInBars,
  }) =>
      _invokeOk('setMetronome', {
        'enabled': enabled,
        'level': level,
        'countInBars': countInBars,
      });

  Future<void> _invokeOk(String method, [Map<String, dynamic>? args]) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(method, args);
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'engine_error',
        message: 'Engine command failed: $method',
      );
    }
  }

  /// Renders [lengthBeats] and saves via system dialog. Null if cancelled.
  Future<String?> exportMix({double lengthBeats = 16.0}) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('exportMix', {
      'lengthBeats': lengthBeats,
    });
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['cancelled'] == true) {
      return null;
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'export_failed',
        message: 'Export failed',
      );
    }
    return result['uri'] as String?;
  }

  Future<void> previewSample(String sampleId) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('previewSample', {
      'sampleId': sampleId,
    });
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'preview_failed',
        message: 'Failed to preview sample',
      );
    }
  }

  Future<void> previewSampleRegion({
    required String sampleId,
    required double start,
    required double end,
    required bool reversed,
  }) =>
      _invokeOk('previewSampleRegion', {
        'sampleId': sampleId,
        'start': start,
        'end': end,
        'reversed': reversed,
      });

  Future<void> previewMidi({
    required List<MidiNoteSnapshot> notes,
    required double lengthBeats,
    required int bpm,
    double startBeat = 0.0,
    bool loop = true,
  }) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('previewMidi', {
      'notes': notes
          .map((n) => {
                'pitch': n.pitch,
                'startBeat': n.startBeat,
                'durationBeats': n.durationBeats,
                'velocity': n.velocity,
              })
          .toList(),
      'lengthBeats': lengthBeats,
      'bpm': bpm,
      'startBeat': startBeat,
      'loop': loop,
    });
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'preview_midi_failed',
        message: 'Failed to preview MIDI',
      );
    }
  }

  Future<void> previewPreset({
    required String deviceType,
    required Map<String, double> params,
    required List<MidiNoteSnapshot> notes,
    required double lengthBeats,
    required int bpm,
    double startBeat = 0.0,
    bool loop = true,
  }) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('previewPreset', {
      'deviceType': deviceType,
      'params': params,
      'notes': notes
          .map((n) => {
                'pitch': n.pitch,
                'startBeat': n.startBeat,
                'durationBeats': n.durationBeats,
                'velocity': n.velocity,
              })
          .toList(),
      'lengthBeats': lengthBeats,
      'bpm': bpm,
      'startBeat': startBeat,
      'loop': loop,
    });
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'preview_preset_failed',
        message: 'Failed to preview preset',
      );
    }
  }

  Future<void> stopPreview() async {
    await _invokeOk('stopPreview');
  }

  Future<List<DeviceParamDescriptor>> getParamDescriptors(
      String deviceType) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getParamDescriptors',
        {'deviceType': deviceType},
      );
      if (result == null || result['ok'] != true) return [];
      final params = result['params'] as List<dynamic>? ?? [];
      return params
          .map((p) => DeviceParamDescriptor.fromMap(p as Map<String, dynamic>))
          .toList();
    } on PlatformException {
      return [];
    }
  }

  /// Opens SAF picker for a WAV/audio file and imports into the sample library.
  Future<ProjectSnapshot?> importSample() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('importSample');
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['cancelled'] == true) {
      return null;
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'import_failed',
        message: 'Failed to import sample',
      );
    }
    return ProjectSnapshot.fromMap(result);
  }

  Future<AudioRecordingSession> beginAudioRecordingSession({
    required String trackId,
    required double startBeat,
    required double sampleRate,
    required String displayName,
    String? targetClipId,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'beginAudioRecordingSession',
      {
        'trackId': trackId,
        'startBeat': startBeat,
        'sampleRate': sampleRate,
        'displayName': displayName,
        'targetClipId': targetClipId ?? '',
      },
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'recording_session_failed',
        message: 'Failed to begin audio recording session',
      );
    }
    return AudioRecordingSession(
      snapshot: _snapshotFromResult(result),
      sampleId: result['sampleId'] as String? ?? '',
      clipId: result['clipId'] as String? ?? '',
    );
  }

  Future<void> startTrackAudioRecording({
    required String sampleId,
    required String clipId,
  }) async {
    await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'startTrackAudioRecording',
      {
        'sampleId': sampleId,
        'clipId': clipId,
      },
    );
  }

  Future<void> ensureRecordAudioPermission() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'ensureRecordAudioPermission',
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'mic_permission_failed',
        message: 'Microphone permission was not granted',
      );
    }
  }

  Future<void> retargetTrackAudioRecording({
    required String sampleId,
    required String clipId,
  }) async {
    await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'retargetTrackAudioRecording',
      {
        'sampleId': sampleId,
        'clipId': clipId,
      },
    );
  }

  Future<void> stopTrackAudioRecording() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'stopTrackAudioRecording',
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'recording_failed',
        message: 'Failed to stop audio recording',
      );
    }
  }

  Future<void> cancelTrackAudioRecording() async {
    await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'cancelTrackAudioRecording',
    );
  }

  Future<double> getTrackAudioRecordingLevel() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getTrackAudioRecordingLevel',
    );
    if (result == null || result['ok'] != true) return 0;
    return (result['level'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0;
  }

  Future<ProjectSnapshot> finishAudioRecordingSession({
    required String sampleId,
    required String clipId,
  }) =>
      _invokeForSnapshot('finishAudioRecordingSession', {
        'sampleId': sampleId,
        'clipId': clipId,
      });

  Future<ProjectSnapshot> cancelAudioRecordingSession({
    required String sampleId,
    required String clipId,
  }) =>
      _invokeForSnapshot('cancelAudioRecordingSession', {
        'sampleId': sampleId,
        'clipId': clipId,
      });

  Future<ProjectSnapshot> registerDemoSample({
    required String id,
    required String name,
    required Uint8List bytes,
  }) =>
      _invokeForSnapshot('registerDemoSample', {
        'id': id,
        'name': name,
        'bytes': bytes,
      });

  /// Select a wavetable for a wavetable synth device.
  Future<void> selectWavetable(String deviceId, String wavetableName) async {
    await _invokeOk('setDeviceStringParameter', {
      'deviceId': deviceId,
      'parameterId': 'wavetable',
      'value': wavetableName,
    });
  }

  /// Opens the system save dialog for a `.audioapp.zip` archive.
  /// Returns the saved document URI, or null if the user cancelled.
  Future<String?> saveProject() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('saveProject');
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['cancelled'] == true) {
      return null;
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'save_failed',
        message: 'Failed to save project',
      );
    }
    return result['uri'] as String? ?? result['path'] as String?;
  }

  /// Opens the system open dialog for a `.audioapp.zip` archive.
  /// Returns null if the user cancelled.
  Future<ProjectSnapshot?> loadProject() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('loadProject');
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['cancelled'] == true) {
      return null;
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'load_failed',
        message: 'Failed to load project',
      );
    }
    return ProjectSnapshot.fromMap(result);
  }

  Future<List<RecentProjectEntry>> getRecentProjects() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('getRecentProjects');
    if (result == null || result['ok'] != true) return const [];
    final projects = result['projects'] as List<dynamic>? ?? const [];
    return projects
        .map(
            (item) => RecentProjectEntry.fromMap(item as Map<dynamic, dynamic>))
        .where((item) => item.uri.isNotEmpty)
        .toList();
  }

  Future<ProjectSnapshot> loadRecentProject(String uri) =>
      _invokeForSnapshot('loadRecentProject', {'uri': uri});

  /// Loads a bundled example project from its raw `project.json` contents.
  /// Unlike [loadRecentProject], this never touches the OS document picker
  /// or the native "recent projects" store.
  Future<ProjectSnapshot> loadExampleProject(String projectJson) =>
      _invokeForSnapshot('loadExampleProject', {'projectJson': projectJson});

  Future<ProjectSnapshot> _invokeForSnapshot(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(method, args);
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'engine_error',
        message: 'Engine command failed: $method',
      );
    }
    return _snapshotFromResult(result);
  }

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
