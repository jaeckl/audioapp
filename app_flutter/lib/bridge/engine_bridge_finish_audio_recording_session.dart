part of 'engine_bridge.dart';

extension EngineBridgeFinishaudiorecordingsessionOperation on EngineBridge {
  Future<ProjectSnapshot> finishAudioRecordingSession({
    required String sampleId,
    required String clipId,
  }) =>
      _invokeForSnapshot('finishAudioRecordingSession', {
        'sampleId': sampleId,
        'clipId': clipId,
      });
}
