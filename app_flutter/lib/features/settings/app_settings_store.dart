import 'package:shared_preferences/shared_preferences.dart';

import 'audio_engine_settings.dart';

/// Persistent preferences that belong to the app rather than to a project.
class AppSettingsStore {
  static const _showWelcomeOnLaunchKey = 'app.show_welcome_on_launch';
  static const _audioEngineProfileKey = 'audio.engine.profile';

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
}
