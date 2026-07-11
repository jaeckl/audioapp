part of 'engine_bridge.dart';

extension EngineBridgeDeletesamplecliptakemarkerOperation on EngineBridge {
  Future<ProjectSnapshot> deleteSampleClipTakeMarker({
    required String clipId,
    required int markerIndex,
  }) =>
      _invokeForSnapshot('deleteSampleClipTakeMarker', {
        'clipId': clipId,
        'markerIndex': markerIndex,
      });
}
