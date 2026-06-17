import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_chain_row.dart';
import 'package:audioapp/features/device_strip/device_strip_card.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeviceChainRow shows insert control after each device', (tester) async {
    final track = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: [
        DeviceSnapshot.fromMap({
          'id': 'dev-1',
          'type': 'simple_sampler',
          'parameters': {'gain': 1.0, 'sampleId': ''},
        }),
        DeviceSnapshot.fromMap({
          'id': 'dev-2',
          'type': 'track_gain',
          'parameters': {'gain': 1.0},
        }),
      ],
      midiClips: [],
      sampleClips: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceChainRow(
            track: track,
            samples: const [],
            playing: false,
            density: DeviceStripSlotDensity.strip,
            onSamplerParameterChanged: (_, __, ___) {},
            onOpenSamplerEditor: (_, __) {},
            onFrequencyChanged: (_, __) {},
            onInsertDevice: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(DeviceStripCard), findsOneWidget);
    expect(find.text('SAMPLER'), findsWidgets);
  });
}
