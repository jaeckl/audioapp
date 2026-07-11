part of 'engine_bridge.dart';

extension EngineBridgeSplitmidicliptakeregionatbeatOperation on EngineBridge {
Future<ProjectSnapshot> splitMidiClipTakeRegionAtBeat({
    required String clipId,
    required double beat,
  }) =>
      _invokeForSnapshot('splitMidiClipTakeRegionAtBeat', {
        'clipId': clipId,
        'beat': beat,
      });
}
