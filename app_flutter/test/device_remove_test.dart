import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_chain_row.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('delete tool rail button invokes remove callback', (tester) async {
    DeviceSnapshot? removed;

    final track = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: [
        DeviceSnapshot.fromMap({
          'id': 'dev-1',
          'type': 'compressor',
          'parameters': {'gain': 1.0},
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
          body: SizedBox(
            height: 320,
            width: 900,
            child: DeviceChainRow(
              track: track,
              samples: const [],
              playing: false,
              bpm: 120,
              density: DeviceStripSlotDensity.strip,
              onSamplerParameterChanged: (_, __, ___) {},
              onOpenSamplerEditor: (_, __) {},
              onFrequencyChanged: (_, __) {},
              onInsertDevice: (_) {},
              onDeleteDevice: (device) => removed = device,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(removed?.id, 'dev-1');
  });
}
