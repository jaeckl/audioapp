part of 'engine_bridge.dart';

extension EngineBridgeBeginaudiorecordingsessionOperation on EngineBridge {
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
}
