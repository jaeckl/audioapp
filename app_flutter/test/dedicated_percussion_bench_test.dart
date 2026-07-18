import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/dedicated_percussion_device_panel.dart';
import 'package:audioapp/features/device_strip/percussion_panel_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in const {
    'hihat_generator': ['Color', 'Tight'],
    'ride_generator': ['Bright', 'Bell'],
    'tom_generator': ['Bend', 'Body'],
    'rimshot_generator': ['Tone', 'Snap'],
  }.entries) {
    testWidgets('${entry.key} uses three compact unnamed cards',
        (tester) async {
      final device = DeviceSnapshot.fromMap({
        'id': entry.key,
        'type': entry.key,
        'parameters': <String, double>{},
      }) as DedicatedPercussionDeviceSnapshot;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 280,
            child: DedicatedPercussionDevicePanel(
              device: device,
              onParameterChanged: (_, __) {},
            ),
          ),
        ),
      ));
      expect(find.byType(PercussionControlCard), findsNWidgets(3));
      expect(find.text(entry.value[0]), findsOneWidget);
      expect(find.text(entry.value[1]), findsOneWidget);
    });
  }
}
