import 'package:audioapp/features/settings/app_settings_store.dart';
import 'package:audioapp/features/settings/audio_engine_settings.dart';
import 'package:audioapp/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Settings contains only persistent app preferences',
      (tester) async {
    var savedValue = true;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          showWelcomeOnLaunch: true,
          onShowWelcomeOnLaunchChanged: (value) async {
            savedValue = value;
          },
        ),
      ),
    );

    expect(find.text('Loop playback'), findsNothing);

    final startupSwitch = find.byKey(const ValueKey('settings-show-welcome'));
    await tester.scrollUntilVisible(startupSwitch, 250);
    expect(find.text('Show project hub on launch'), findsOneWidget);
    await tester.tap(startupSwitch);
    await tester.pumpAndSettle();
    expect(savedValue, isFalse);
  });

  testWidgets('custom audio controls apply direct stream values',
      (tester) async {
    var savedProfile = AudioEngineProfile.balanced;
    var savedCustom = const AudioEngineCustomSettings();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          showWelcomeOnLaunch: true,
          onShowWelcomeOnLaunchChanged: (_) async {},
          onAudioEngineConfigurationChanged: (profile, customSettings) async {
            savedProfile = profile;
            savedCustom = customSettings;
            return AudioEngineStatus.fromMap({
              'profile': profile.storageValue,
              'platform': 'AAudio',
              'sampleRate': customSettings.sampleRate,
              'streamOpen': false,
            });
          },
        ),
      ),
    );

    final lowLatency = find.byKey(const ValueKey('settings-audio-low_latency'));
    await tester.tap(lowLatency);
    await tester.pumpAndSettle();
    expect(savedProfile, AudioEngineProfile.lowLatency);

    final customProfile = find.byKey(const ValueKey('settings-audio-custom'));
    await tester.scrollUntilVisible(customProfile, 200);
    await tester.tap(customProfile);
    await tester.pumpAndSettle();
    expect(savedProfile, AudioEngineProfile.custom);
    expect(
      find.byKey(const ValueKey('settings-custom-audio-controls')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('settings-custom-sample-rate')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('96000 Hz').last);
    await tester.pumpAndSettle();
    final apply = find.byKey(const ValueKey('settings-apply-custom-audio'));
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(savedCustom.sampleRate, 96000);
  });

  test('startup preference survives a store round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppSettingsStore();

    expect(await store.loadShowWelcomeOnLaunch(), isTrue);
    await store.saveShowWelcomeOnLaunch(false);
    expect(await store.loadShowWelcomeOnLaunch(), isFalse);
    expect(await store.loadAudioEngineProfile(), AudioEngineProfile.balanced);
    await store.saveAudioEngineProfile(AudioEngineProfile.safe);
    expect(await store.loadAudioEngineProfile(), AudioEngineProfile.safe);
    const custom = AudioEngineCustomSettings(
      sampleRate: 96000,
      framesPerCallback: 1024,
      bufferCapacityFrames: 8192,
      bufferSizeFrames: 8192,
      exclusive: true,
    );
    await store.saveAudioEngineCustomSettings(custom);
    final restored = await store.loadAudioEngineCustomSettings();
    expect(restored.sampleRate, 96000);
    expect(restored.framesPerCallback, 1024);
    expect(restored.bufferCapacityFrames, 8192);
    expect(restored.bufferSizeFrames, 8192);
    expect(restored.exclusive, isTrue);
  });
}
