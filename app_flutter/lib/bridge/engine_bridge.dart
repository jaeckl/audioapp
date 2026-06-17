import 'package:flutter/services.dart';

import 'project_snapshot.dart';

/// Flutter ↔ native engine bridge (MethodChannel).
class EngineBridge {
  EngineBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.audioapp.daw/engine');

  final MethodChannel _channel;

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

  Future<ProjectSnapshot> addTrack({String? name}) async {
    return _invokeForSnapshot('addTrack', {'name': name ?? ''});
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

  Future<ProjectSnapshot> setDeviceParameter({
    required String deviceId,
    required String parameterId,
    required double value,
  }) async {
    return _invokeForSnapshot('setDeviceParameter', {
      'deviceId': deviceId,
      'parameterId': parameterId,
      'value': value,
    });
  }

  Future<ProjectSnapshot> setDeviceStringParameter({
    required String deviceId,
    required String parameterId,
    required String value,
  }) async {
    return _invokeForSnapshot('setDeviceStringParameter', {
      'deviceId': deviceId,
      'parameterId': parameterId,
      'value': value,
    });
  }

  Future<ProjectSnapshot> setMasterGain(double gain) async {
    return _invokeForSnapshot('setMasterGain', {'gain': gain});
  }

  Future<ProjectSnapshot> setPlayheadBeats(double playheadBeats) async {
    return _invokeForSnapshot('setPlayheadBeats', {'playheadBeats': playheadBeats});
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
  }) async {
    return _invokeForSnapshot('setClipLength', {
      'clipId': clipId,
      'lengthBeats': lengthBeats,
    });
  }

  Future<ProjectSnapshot> setBpm(int bpm) async {
    return _invokeForSnapshot('setBpm', {'bpm': bpm});
  }

  Future<ProjectSnapshot> deleteTrack(String trackId) async {
    return _invokeForSnapshot('deleteTrack', {'trackId': trackId});
  }

  Future<ProjectSnapshot> deleteClip(String clipId) async {
    return _invokeForSnapshot('deleteClip', {'clipId': clipId});
  }

  Future<ProjectSnapshot> duplicateClip(String clipId) async {
    return _invokeForSnapshot('duplicateClip', {'clipId': clipId});
  }

  Future<ProjectSnapshot> setLoopEnabled(bool enabled) async {
    return _invokeForSnapshot('setLoopEnabled', {'enabled': enabled});
  }

  Future<ProjectSnapshot> setLoopLengthBeats(double lengthBeats) async {
    return _invokeForSnapshot('setLoopLengthBeats', {'lengthBeats': lengthBeats});
  }

  Future<void> enterPlayMode() async {
    await _invokeOk('enterPlayMode');
  }

  Future<ProjectSnapshot> setRecordArmed(bool armed) async {
    return _invokeForSnapshot('setRecordArmed', {'armed': armed});
  }

  Future<void> noteOn({required int pitch, required double velocity}) async {
    await _invokeOk('noteOn', {'pitch': pitch, 'velocity': velocity});
  }

  Future<void> noteOff({required int pitch}) async {
    await _invokeOk('noteOff', {'pitch': pitch});
  }

  Future<void> allNotesOff() async {
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

  Future<void> _invokeOk(String method, [Map<String, dynamic>? args]) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(method, args);
    if (result == null) {
      throw PlatformException(code: 'null_response', message: 'No response from engine');
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
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('exportMix', {
      'lengthBeats': lengthBeats,
    });
    if (result == null) {
      throw PlatformException(code: 'null_response', message: 'No response from engine');
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
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('previewSample', {
      'sampleId': sampleId,
    });
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'preview_failed',
        message: 'Failed to preview sample',
      );
    }
  }

  /// Opens SAF picker for a WAV/audio file and imports into the sample library.
  Future<ProjectSnapshot?> importSample() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('importSample');
    if (result == null) {
      throw PlatformException(code: 'null_response', message: 'No response from engine');
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

  /// Opens the system save dialog for a `.audioapp.zip` archive.
  /// Returns the saved document URI, or null if the user cancelled.
  Future<String?> saveProject() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('saveProject');
    if (result == null) {
      throw PlatformException(code: 'null_response', message: 'No response from engine');
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
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('loadProject');
    if (result == null) {
      throw PlatformException(code: 'null_response', message: 'No response from engine');
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

  Future<ProjectSnapshot> _invokeForSnapshot(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(method, args);
    if (result == null) {
      throw PlatformException(code: 'null_response', message: 'No response from engine');
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'engine_error',
        message: 'Engine command failed: $method',
      );
    }
    return ProjectSnapshot.fromMap(result);
  }
}
