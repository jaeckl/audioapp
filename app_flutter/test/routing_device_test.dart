import 'package:audioapp/bridge/project_snapshot.dart';
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
    expect(find.text('MIDI Delay'), findsOneWidget);
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
                  trackId: 'track-1',
                  deviceIndex: 0,
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

  test('routing sources disable cycles and expose MIDI device outputs', () {
    final snapshot = ProjectSnapshot.fromMap({
      'snapshot': {
        'selectedTrackId': 'track-a',
        'tracks': [
          {
            'id': 'track-a', 'name': 'A',
            'devices': [
              {'id': 'a-osc', 'type': 'simple_oscillator', 'parameters': {'frequency': 440.0}},
              {'id': 'a-recv', 'type': 'audio_receiver', 'parameters': {'sourceId': 'b-osc'}},
            ],
          },
          {
            'id': 'track-b', 'name': 'B',
            'devices': [
              {'id': 'b-osc', 'type': 'simple_oscillator', 'parameters': {'frequency': 220.0}},
              {'id': 'b-recv', 'type': 'audio_receiver', 'parameters': {'sourceId': ''}},
              {'id': 'b-after', 'type': 'simple_oscillator', 'parameters': {'frequency': 330.0}},
              {'id': 'b-delay', 'type': 'midi_delay', 'parameters': {}},
              {'id': 'b-midi-recv', 'type': 'midi_receiver', 'parameters': {'sourceId': ''}},
            ],
          },
        ],
      },
    });
    final trackB = snapshot.tracks[1];
    final audioReceiver = trackB.devices[1] as RoutingDeviceSnapshot;
    final audioSources = buildRoutingSourceOptions(snapshot, trackB, audioReceiver);
    expect(audioSources.firstWhere((source) => source.id == 'a-osc').disabled, isTrue);
    expect(audioSources.firstWhere((source) => source.id == 'b-after').disabledReason,
        'must be before receiver');

    final midiReceiver = trackB.devices[4] as RoutingDeviceSnapshot;
    final midiSources = buildRoutingSourceOptions(snapshot, trackB, midiReceiver);
    expect(midiSources.any((source) => source.id == 'b-delay'), isTrue);
    expect(midiSources.any((source) => source.id == 'track-midi:track-a'), isTrue);
  });

  testWidgets('routing panel can disconnect', (tester) async {
    String? selectedSource;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
      width: RoutingDevicePanel.designWidth,
      height: 270,
      child: RoutingDevicePanel(
        device: const RoutingDeviceSnapshot(
          id: 'route-1', type: 'audio_receiver', bypassed: false,
          sourceId: 'device-7', routeMix: 1,
        ),
        sources: const [RoutingSourceOption(
          id: 'device-7', label: 'Source', isMidi: false,
          trackId: 'track-1', deviceIndex: 0,
        )],
        onSourceChanged: (value) => selectedSource = value,
        onParameterChanged: (_, __) {},
      ),
    ))));
    await tester.tap(find.byKey(const ValueKey('route-source')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disconnect').last);
    await tester.pumpAndSettle();
    expect(selectedSource, '');
  });
}
