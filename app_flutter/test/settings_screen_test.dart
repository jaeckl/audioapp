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
    var savedProfile = AudioEngineProfile.balanced;
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          showWelcomeOnLaunch: true,
          onShowWelcomeOnLaunchChanged: (value) async {
            savedValue = value;
          },
          onAudioEngineProfileChanged: (profile) async {
            savedProfile = profile;
            return AudioEngineStatus.fromMap({
              'profile': profile.storageValue,
              'platform': 'AAudio',
              'sampleRate': 48000,
              'streamOpen': false,
            });
          },
        ),
      ),
    );

    expect(find.text('Show project hub on launch'), findsOneWidget);
    expect(find.text('Loop playback'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-show-welcome')));
    await tester.pumpAndSettle();
    expect(savedValue, isFalse);

    await tester.tap(
      find.byKey(const ValueKey('settings-audio-low_latency')),
    );
    await tester.pumpAndSettle();
    expect(savedProfile, AudioEngineProfile.lowLatency);
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
  });
}
