import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/clap_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/crash_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/cymbal_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/kick_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/snare_generator_device_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeviceSnapshot percussion(String type, {bool keyTrack = true}) =>
      DeviceSnapshot.fromMap({
        'id': type,
        'type': type,
        'parameters': <String, double>{
          switch (type) {
            'kick_generator' => 'kickKeyTrack',
            'snare_generator' => 'snareKeyTrack',
            'clap_generator' => 'clapKeyTrack',
            'cymbal_generator' => 'cymbalKeyTrack',
            'crash_generator' => 'crashKeyTrack',
            _ => throw StateError('Unexpected percussion type'),
          }: keyTrack ? 1.0 : 0.0,
        },
      });

  test('new keytrack defaults preserve legacy percussion tuning', () {
    expect(
      (DeviceSnapshot.fromMap({
        'type': 'kick_generator',
      }) as KickGeneratorDeviceSnapshot)
          .kickKeyTrack,
      1.0,
    );
    expect(
      (DeviceSnapshot.fromMap({
        'type': 'snare_generator',
      }) as SnareGeneratorDeviceSnapshot)
          .snareKeyTrack,
      1.0,
    );
    expect(
      (DeviceSnapshot.fromMap({
        'type': 'clap_generator',
      }) as ClapGeneratorDeviceSnapshot)
          .clapKeyTrack,
      0.0,
    );
    expect(
      (DeviceSnapshot.fromMap({
        'type': 'cymbal_generator',
      }) as CymbalGeneratorDeviceSnapshot)
          .cymbalKeyTrack,
      0.0,
    );
    expect(
      (DeviceSnapshot.fromMap({
        'type': 'crash_generator',
      }) as CrashGeneratorDeviceSnapshot)
          .crashKeyTrack,
      0.0,
    );
  });

  Future<void> pumpPanel(
    WidgetTester tester,
    String type,
    void Function(String, double) onChanged, {
    bool keyTrack = true,
  }) async {
    final device = percussion(type, keyTrack: keyTrack);
    final panel = switch (device) {
      KickGeneratorDeviceSnapshot d => KickGeneratorDevicePanel(
          device: d,
          onParameterChanged: onChanged,
        ),
      SnareGeneratorDeviceSnapshot d => SnareGeneratorDevicePanel(
          device: d,
          onParameterChanged: onChanged,
        ),
      ClapGeneratorDeviceSnapshot d => ClapGeneratorDevicePanel(
          device: d,
          selectedTab: ClapDeviceTab.tone,
          onParameterChanged: onChanged,
        ),
      CymbalGeneratorDeviceSnapshot d => CymbalGeneratorDevicePanel(
          device: d,
          onParameterChanged: onChanged,
        ),
      CrashGeneratorDeviceSnapshot d => CrashGeneratorDevicePanel(
          device: d,
          onParameterChanged: onChanged,
        ),
      _ => throw StateError('Unexpected percussion type'),
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 480, height: 300, child: panel),
        ),
      ),
    );
    await tester.pump();
  }

  for (final entry in const <String, String>{
    'kick_generator': 'kickKeyTrack',
    'snare_generator': 'snareKeyTrack',
    'clap_generator': 'clapKeyTrack',
    'cymbal_generator': 'cymbalKeyTrack',
    'crash_generator': 'crashKeyTrack',
  }.entries) {
    testWidgets('${entry.key} exposes pitch and keytrack', (tester) async {
      String? changedParameter;
      double? changedValue;
      await pumpPanel(tester, entry.key, (parameter, value) {
        changedParameter = parameter;
        changedValue = value;
      });

      expect(find.text('Tune'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('drum-keytrack-toggle')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('drum-keytrack-toggle')));
      expect(changedParameter, entry.value);
      expect(changedValue, 0.0);
    });

    testWidgets('${entry.key} labels fixed control as pitch', (tester) async {
      await pumpPanel(tester, entry.key, (_, __) {}, keyTrack: false);
      expect(find.text('Pitch'), findsOneWidget);
      expect(find.text('Tune'), findsNothing);
    });
  }
}
