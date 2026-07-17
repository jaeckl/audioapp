import 'package:audioapp/features/settings/app_settings_store.dart';
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

    expect(find.text('Show project hub on launch'), findsOneWidget);
    expect(find.text('Loop playback'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-show-welcome')));
    await tester.pumpAndSettle();
    expect(savedValue, isFalse);
  });

  test('startup preference survives a store round trip', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppSettingsStore();

    expect(await store.loadShowWelcomeOnLaunch(), isTrue);
    await store.saveShowWelcomeOnLaunch(false);
    expect(await store.loadShowWelcomeOnLaunch(), isFalse);
  });
}
