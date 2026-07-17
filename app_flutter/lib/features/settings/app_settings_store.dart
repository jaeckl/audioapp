import 'package:shared_preferences/shared_preferences.dart';

/// Persistent preferences that belong to the app rather than to a project.
class AppSettingsStore {
  static const _showWelcomeOnLaunchKey = 'app.show_welcome_on_launch';

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
}
