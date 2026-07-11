part of 'engine_bridge.dart';

extension EngineBridgeImportsampleOperation on EngineBridge {
  Future<ProjectSnapshot?> importSample() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('importSample');
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['cancelled'] == true) {
      return null;
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'import_failed',
        message: 'Failed to import sample',
      );
    }
    return ProjectSnapshot.fromMap(result);
  }
}
