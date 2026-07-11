part of 'engine_bridge.dart';

extension EngineBridgeExportmixOperation on EngineBridge {
  Future<String?> exportMix({double lengthBeats = 16.0}) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('exportMix', {
      'lengthBeats': lengthBeats,
    });
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['cancelled'] == true) {
      return null;
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'export_failed',
        message: 'Export failed',
      );
    }
    return result['uri'] as String?;
  }
}
