part of 'engine_bridge.dart';

extension EngineBridgeMovemidicliptakemarkerOperation on EngineBridge {
  Future<ProjectSnapshot> moveMidiClipTakeMarker({
    required String clipId,
    required int markerIndex,
    required double beat,
  }) =>
      _invokeForSnapshot('moveMidiClipTakeMarker', {
        'clipId': clipId,
        'markerIndex': markerIndex,
        'beat': beat,
      });
}
