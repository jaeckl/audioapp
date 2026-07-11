part of 'engine_bridge.dart';

extension EngineBridgeSetsampleclipwarpOperation on EngineBridge {
Future<ProjectSnapshot> setSampleClipWarp({
    required String clipId,
    required bool warpRepitch,
  }) =>
      _invokeForSnapshot('setSampleClipWarp', {
        'clipId': clipId,
        'warpRepitch': warpRepitch,
      });
}
