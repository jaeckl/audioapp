part of 'engine_bridge.dart';

extension EngineBridgeSplitsamplecliptakeregionatbeatOperation on EngineBridge {
Future<ProjectSnapshot> splitSampleClipTakeRegionAtBeat({
    required String clipId,
    required double beat,
  }) =>
      _invokeForSnapshot('splitSampleClipTakeRegionAtBeat', {
        'clipId': clipId,
        'beat': beat,
      });
}
