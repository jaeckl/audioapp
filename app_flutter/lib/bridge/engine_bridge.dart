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
