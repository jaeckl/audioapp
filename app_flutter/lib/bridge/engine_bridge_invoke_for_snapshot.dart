part of 'engine_bridge.dart';

extension EngineBridgeInvokeforsnapshotOperation on EngineBridge {
  Future<ProjectSnapshot> _invokeForSnapshot(
    String method, [
    Map<String, dynamic>? args,
  ]) async {
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
    return _snapshotFromResult(result);
  }
}
