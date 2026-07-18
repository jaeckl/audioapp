import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/daw_shell.dart';
import 'bridge/engine_bridge.dart';
import 'features/settings/app_settings_store.dart';
import 'features/settings/audio_engine_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  var showWelcomeOnLaunch = true;
  var audioEngineProfile = AudioEngineProfile.balanced;
  var customAudioSettings = const AudioEngineCustomSettings();
  try {
    final settings = AppSettingsStore();
    showWelcomeOnLaunch = await settings.loadShowWelcomeOnLaunch();
    audioEngineProfile = await settings.loadAudioEngineProfile();
    customAudioSettings = await settings.loadAudioEngineCustomSettings();
  } catch (_) {
    // A preference failure must never prevent the DAW from opening.
  }
  runApp(AudioApp(
    showWelcomeOnLaunch: showWelcomeOnLaunch,
    audioEngineProfile: audioEngineProfile,
    customAudioSettings: customAudioSettings,
  ));
}

class AudioApp extends StatelessWidget {
  const AudioApp({
    super.key,
    this.showWelcomeOnLaunch = true,
    this.audioEngineProfile = AudioEngineProfile.balanced,
    this.customAudioSettings = const AudioEngineCustomSettings(),
  });

  final bool showWelcomeOnLaunch;
  final AudioEngineProfile audioEngineProfile;
  final AudioEngineCustomSettings customAudioSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AudioApp DAW',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0E14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C5CE7),
          brightness: Brightness.dark,
          surface: const Color(0xFF0E0E14),
        ),
        useMaterial3: true,
      ),
      home: DawShell(
        bridge: EngineBridge(),
        showWelcomeOnLaunch: showWelcomeOnLaunch,
        initialAudioEngineProfile: audioEngineProfile,
        initialCustomAudioSettings: customAudioSettings,
      ),
    );
  }
}
