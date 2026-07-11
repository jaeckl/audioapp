part of 'engine_bridge.dart';

extension EngineBridgeSetsamplecliptakeatbeatOperation on EngineBridge {
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
}
