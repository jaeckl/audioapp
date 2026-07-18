part of 'engine_bridge.dart';

extension EngineBridgeAudioEngineOperation on EngineBridge {
  Future<AudioEngineStatus> configureAudioEngine(
    AudioEngineProfile profile,
    AudioEngineCustomSettings customSettings,
  ) async {
    if (profile == AudioEngineProfile.custom) customSettings.validate();
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'configureAudioEngine',
      {
        'profile': profile.storageValue,
        ...customSettings.toMap(),
      },
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'audio_config_failed',
        message: 'Could not configure the audio engine',
      );
    }
    return AudioEngineStatus.fromMap(result);
  }

  Future<AudioEngineStatus> getAudioEngineStatus() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getAudioEngineStatus',
    );
    if (result == null || result['ok'] != true) {
      throw PlatformException(
        code: result?['error']?.toString() ?? 'audio_status_failed',
        message: 'Could not read audio engine status',
      );
    }
    return AudioEngineStatus.fromMap(result);
  }
}
