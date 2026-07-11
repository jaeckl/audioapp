part of 'engine_bridge.dart';

extension EngineBridgeMovesamplecliptakemarkerOperation on EngineBridge {
  Future<ProjectSnapshot> moveSampleClipTakeMarker({
    required String clipId,
    required int markerIndex,
    required double beat,
  }) =>
      _invokeForSnapshot('moveSampleClipTakeMarker', {
        'clipId': clipId,
        'markerIndex': markerIndex,
        'beat': beat,
      });
}
