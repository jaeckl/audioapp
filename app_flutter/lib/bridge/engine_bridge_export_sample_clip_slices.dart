part of 'engine_bridge.dart';

extension EngineBridgeExportsampleclipslicesOperation on EngineBridge {
  Future<ProjectSnapshot> exportSampleClipSlices({
    required String clipId,
    int firstNote = 36,
  }) =>
      _invokeForSnapshot('exportSampleClipSlices', {
        'clipId': clipId,
        'firstNote': firstNote,
      });
}
