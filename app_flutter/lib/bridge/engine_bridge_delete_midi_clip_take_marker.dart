part of 'engine_bridge.dart';

extension EngineBridgeDeletemidicliptakemarkerOperation on EngineBridge {
  Future<ProjectSnapshot> deleteMidiClipTakeMarker({
    required String clipId,
    required int markerIndex,
  }) =>
      _invokeForSnapshot('deleteMidiClipTakeMarker', {
        'clipId': clipId,
        'markerIndex': markerIndex,
      });
}
