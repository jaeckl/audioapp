part of 'engine_bridge.dart';

extension EngineBridgeInvokerawOperation on EngineBridge {
  Future<Map<dynamic, dynamic>> invokeRaw(String method,
      [Map<String, dynamic>? args]) async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>(method, args);
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'engine_error',
        message: 'Engine command failed: $method',
      );
    }
    // Inline deltaXml to delta map so all callers see result['delta'].
    final deltaXml = result['deltaXml'] as String?;
    if (deltaXml != null && deltaXml.isNotEmpty) {
      result['delta'] = parseDeltaXml(deltaXml);
    }
    return result;
  }
}
