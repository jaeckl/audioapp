part of 'engine_bridge.dart';

extension EngineBridgeGettransportstateOperation on EngineBridge {
  Future<TransportState> getTransportState() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('getTransportState');
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'engine_error',
        message: 'Engine command failed: getTransportState',
      );
    }
    return TransportState.fromMap(result);
  }
}
