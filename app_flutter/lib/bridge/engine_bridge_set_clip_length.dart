part of 'engine_bridge.dart';

extension EngineBridgeSetcliplengthOperation on EngineBridge {
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
}
