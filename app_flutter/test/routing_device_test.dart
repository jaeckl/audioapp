import 'package:audioapp/bridge/device_snapshot.dart';
import 'package:audioapp/features/device_strip/device_picker_sheet.dart';
import 'package:audioapp/features/device_strip/routing_device_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routing snapshot parses endpoint state', () {
    final snapshot = DeviceSnapshot.fromMap(<dynamic, dynamic>{
      'id': 'route-1',
      'type': 'audio_receiver',
      'parameters': <dynamic, dynamic>{
        'sourceId': 'device-7',
        'routeMix': 0.75,
      },
    }) as RoutingDeviceSnapshot;

    expect(snapshot.isAudioRoute, isTrue);
    expect(snapshot.sourceId, 'device-7');
    expect(snapshot.routeMix, 0.75);
    expect(snapshot.withParameter('routeMix', 2).routeMix, 1);
  });

  testWidgets('device picker lists receiver devices', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showDevicePickerSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Audio Receiver'), findsOneWidget);
    expect(find.text('MIDI Receiver'), findsOneWidget);
    expect(find.text('Audio Sender'), findsNothing);
    expect(find.text('MIDI Sender'), findsNothing);
  });

  testWidgets('routing panel selects a source', (tester) async {
    String? selectedSource;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: RoutingDevicePanel.designWidth,
            height: 270,
            child: RoutingDevicePanel(
              device: const RoutingDeviceSnapshot(
                id: 'route-1',
                type: 'audio_receiver',
                bypassed: false,
                sourceId: '',
                routeMix: 0.5,
              ),
              sources: const [
                RoutingSourceOption(
                  id: 'device-7',
                  label: 'Drums · Oscillator',
                  isMidi: false,
                ),
              ],
              onSourceChanged: (value) => selectedSource = value,
              onParameterChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('route-source')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drums · Oscillator').last);
    await tester.pumpAndSettle();
    expect(selectedSource, 'device-7');
    expect(tester.takeException(), isNull);
  });
}
