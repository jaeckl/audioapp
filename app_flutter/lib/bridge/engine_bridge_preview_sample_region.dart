part of 'engine_bridge.dart';

extension EngineBridgePreviewsampleregionOperation on EngineBridge {
  Future<void> previewSampleRegion({
    required String sampleId,
    required double start,
    required double end,
    required bool reversed,
  }) =>
      _invokeOk('previewSampleRegion', {
        'sampleId': sampleId,
        'start': start,
        'end': end,
        'reversed': reversed,
      });
}
