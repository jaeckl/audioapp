part of 'engine_bridge.dart';

extension EngineBridgeSetmidicliptakeatbeatOperation on EngineBridge {
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
}
