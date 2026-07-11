part of 'engine_bridge.dart';

extension EngineBridgeSetmidicliptakeregiontakeOperation on EngineBridge {
Future<ProjectSnapshot> setMidiClipTakeRegionTake({
    required String clipId,
    required int regionIndex,
    required String takeId,
  }) =>
      _invokeForSnapshot('setMidiClipTakeRegionTake', {
        'clipId': clipId,
        'regionIndex': regionIndex,
        'takeId': takeId,
      });
}
