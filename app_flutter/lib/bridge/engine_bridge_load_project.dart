part of 'engine_bridge.dart';

extension EngineBridgeLoadprojectOperation on EngineBridge {
  Future<ProjectSnapshot?> loadProject() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('loadProject');
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['cancelled'] == true) {
      return null;
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'load_failed',
        message: 'Failed to load project',
      );
    }
    return ProjectSnapshot.fromMap(result);
  }
}
