part of 'engine_bridge.dart';

extension EngineBridgeSaveprojectOperation on EngineBridge {
Future<String?> saveProject() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('saveProject');
    if (result == null) {
      throw PlatformException(
          code: 'null_response', message: 'No response from engine');
    }
    if (result['cancelled'] == true) {
      return null;
    }
    if (result['ok'] != true) {
      throw PlatformException(
        code: result['error']?.toString() ?? 'save_failed',
        message: 'Failed to save project',
      );
    }
    return result['uri'] as String? ?? result['path'] as String?;
  }
}
