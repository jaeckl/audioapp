part of 'engine_bridge.dart';

extension EngineBridgeFinishmidirecordingsessionOperation on EngineBridge {
  Future<ProjectSnapshot> finishMidiRecordingSession({double? endBeat}) async {
    return _invokeForSnapshot('finishMidiRecordingSession', {
      if (endBeat != null) 'endBeat': endBeat,
    });
  }
}
