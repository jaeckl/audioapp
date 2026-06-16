import 'package:audioapp/app/daw_shell.dart';
import 'package:audioapp/bridge/engine_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.audioapp.daw/engine');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'ping':
          return 'pong';
        case 'play':
        case 'stop':
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('DAW shell shows arrangement and transport', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arrangement'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.textContaining('Engine:'), findsOneWidget);
  });

  testWidgets('Selecting track shows device strip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DawShell(bridge: EngineBridge(channel: channel))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Track 1'));
    await tester.pumpAndSettle();

    expect(find.text('Device strip'), findsOneWidget);
    expect(find.text('Oscillator'), findsOneWidget);
  });
}
