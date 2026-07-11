part of 'engine_bridge.dart';

extension EngineBridgePreviewsampleOperation on EngineBridge {
  Future<void> previewSample(String sampleId) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('previewSample', {
      'sampleId': sampleId,
    });
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'preview_failed',
        message: 'Failed to preview sample',
      );
    }
  }
}
