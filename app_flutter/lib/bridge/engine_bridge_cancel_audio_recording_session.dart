part of 'engine_bridge.dart';

extension EngineBridgeCancelaudiorecordingsessionOperation on EngineBridge {
  Future<ProjectSnapshot> cancelAudioRecordingSession({
    required String sampleId,
    required String clipId,
  }) =>
      _invokeForSnapshot('cancelAudioRecordingSession', {
        'sampleId': sampleId,
        'clipId': clipId,
      });
}
