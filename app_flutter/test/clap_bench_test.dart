import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/clap_generator_device_panel.dart';
import 'package:audioapp/features/device_strip/percussion_panel_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clap uses the compact asymmetric percussion bench',
      (tester) async {
    final clap = DeviceSnapshot.fromMap({
      'id': 'clap',
      'type': 'clap_generator',
      'parameters': <String, double>{},
    }) as ClapGeneratorDeviceSnapshot;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 280,
            child: ClapGeneratorDevicePanel(
              device: clap,
              onParameterChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PercussionControlCard), findsNWidgets(2));
    for (final label in const [
      'Pitch',
      'Bursts',
      'Spread',
      'Tone',
      'Room',
      'Decay',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(ClapGeneratorDevicePanel.containerTabs, isEmpty);
  });
}
