import 'package:shared_preferences/shared_preferences.dart';

import 'audio_engine_settings.dart';

/// Persistent preferences that belong to the app rather than to a project.
class AppSettingsStore {
  static const _showWelcomeOnLaunchKey = 'app.show_welcome_on_launch';
  static const _audioEngineProfileKey = 'audio.engine.profile';
  static const _customSampleRateKey = 'audio.engine.custom.sample_rate';
  static const _customCallbackFramesKey = 'audio.engine.custom.callback_frames';
  static const _customBufferCapacityKey = 'audio.engine.custom.buffer_capacity';
  static const _customBufferSizeKey = 'audio.engine.custom.buffer_size';
  static const _customLowLatencyKey = 'audio.engine.custom.low_latency';
  static const _customExclusiveKey = 'audio.engine.custom.exclusive';

  Future<bool> loadShowWelcomeOnLaunch() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_showWelcomeOnLaunchKey) ?? true;
  }

  Future<void> saveShowWelcomeOnLaunch(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_showWelcomeOnLaunchKey, value);
    if (!saved) {
      throw StateError('Could not save the startup preference.');
    }
  }

  Future<AudioEngineProfile> loadAudioEngineProfile() async {
    final preferences = await SharedPreferences.getInstance();
    return AudioEngineProfileDetails.fromStorage(
      preferences.getString(_audioEngineProfileKey),
    );
  }

  Future<void> saveAudioEngineProfile(AudioEngineProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _audioEngineProfileKey,
      profile.storageValue,
    );
    if (!saved) {
      throw StateError('Could not save the audio engine profile.');
    }
  }

  Future<AudioEngineCustomSettings> loadAudioEngineCustomSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final settings = AudioEngineCustomSettings(
      sampleRate: preferences.getInt(_customSampleRateKey) ?? 48000,
      framesPerCallback: preferences.getInt(_customCallbackFramesKey) ?? 1024,
      bufferCapacityFrames:
          preferences.getInt(_customBufferCapacityKey) ?? 8192,
      bufferSizeFrames: preferences.getInt(_customBufferSizeKey) ?? 8192,
      lowLatency: preferences.getBool(_customLowLatencyKey) ?? true,
      exclusive: preferences.getBool(_customExclusiveKey) ?? false,
    );
    try {
      settings.validate();
      return settings;
    } on FormatException {
      return const AudioEngineCustomSettings();
    }
  }

  Future<void> saveAudioEngineCustomSettings(
    AudioEngineCustomSettings settings,
  ) async {
    settings.validate();
    final preferences = await SharedPreferences.getInstance();
    final saved = await Future.wait<bool>([
      preferences.setInt(_customSampleRateKey, settings.sampleRate),
      preferences.setInt(
        _customCallbackFramesKey,
        settings.framesPerCallback,
      ),
      preferences.setInt(
        _customBufferCapacityKey,
        settings.bufferCapacityFrames,
      ),
      preferences.setInt(_customBufferSizeKey, settings.bufferSizeFrames),
      preferences.setBool(_customLowLatencyKey, settings.lowLatency),
      preferences.setBool(_customExclusiveKey, settings.exclusive),
    ]);
    if (saved.any((value) => !value)) {
      throw StateError('Could not save the custom audio settings.');
    }
  }
}
