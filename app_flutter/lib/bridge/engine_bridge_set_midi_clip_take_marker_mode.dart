part of 'engine_bridge.dart';

extension EngineBridgeSetmidicliptakemarkermodeOperation on EngineBridge {
Future<ProjectSnapshot> setMidiClipTakeMarkerMode({
    required String clipId,
    required int markerIndex,
    required bool holdPrevious,
  }) =>
      _invokeForSnapshot('setMidiClipTakeMarkerMode', {
        'clipId': clipId,
        'markerIndex': markerIndex,
        'holdPrevious': holdPrevious,
      });
}
