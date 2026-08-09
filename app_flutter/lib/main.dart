import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/daw_shell.dart';
import 'bridge/engine_bridge.dart';
import 'features/settings/app_settings_store.dart';
import 'features/settings/audio_engine_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _enableFullscreenSystemUi();
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

Future<void> _enableFullscreenSystemUi() async {
  // Hide status + nav bars; swipe edge briefly reveals them.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

class AudioApp extends StatefulWidget {
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
  State<AudioApp> createState() => _AudioAppState();
}

class _AudioAppState extends State<AudioApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_enableFullscreenSystemUi());
    }
  }

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
        showWelcomeOnLaunch: widget.showWelcomeOnLaunch,
        initialAudioEngineProfile: widget.audioEngineProfile,
        initialCustomAudioSettings: widget.customAudioSettings,
      ),
    );
  }
}
