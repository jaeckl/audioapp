part of 'engine_bridge.dart';

extension EngineBridgeSetsamplecliptakeregiontakeOperation on EngineBridge {
Future<ProjectSnapshot> setSampleClipTakeRegionTake({
    required String clipId,
    required int regionIndex,
    required String takeId,
  }) =>
      _invokeForSnapshot('setSampleClipTakeRegionTake', {
        'clipId': clipId,
        'regionIndex': regionIndex,
        'takeId': takeId,
      });
}
