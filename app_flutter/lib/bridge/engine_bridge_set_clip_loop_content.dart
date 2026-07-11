part of 'engine_bridge.dart';

extension EngineBridgeSetcliploopcontentOperation on EngineBridge {
Future<ProjectSnapshot> setClipLoopContent({
    required String clipId,
    required bool loopContent,
  }) async {
    return _invokeForSnapshot('setClipLoopContent', {
      'clipId': clipId,
      'loopContent': loopContent,
    });
  }
}
