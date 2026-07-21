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
              onInsertDevice: (_) async => null,
              onDeleteDevice: (device) async {
                removed = device;
                return null;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(removed?.id, 'dev-1');
  });

  testWidgets('substrip delete removes the targeted nested device', (tester) async {
    tester.view.physicalSize = const Size(2400, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? removedChildId;
    String? removeMethod;

    final chain = ChainDeviceSnapshot(
      id: 'chain-1',
      bypassed: false,
      devices: [
        DeviceSnapshot.fromMap({
          'id': 'chain-child-1',
          'type': 'compressor',
          'parameters': {'gain': 1.0},
        }),
        DeviceSnapshot.fromMap({
          'id': 'chain-child-2',
          'type': 'track_gain',
          'parameters': {'gain': 1.0},
        }),
      ],
    );

    final track = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: [chain],
      midiClips: [],
      sampleClips: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 320,
            width: 1200,
            child: DeviceChainRow(
              track: track,
              samples: const [],
              playing: false,
              bpm: 120,
              density: DeviceStripSlotDensity.strip,
              onSamplerParameterChanged: (_, __, ___) {},
              onOpenSamplerEditor: (_, __) {},
              onFrequencyChanged: (_, __) {},
              onInsertDevice: (_) async => null,
              onModulationBridgeCall: (method, args) async {
                removeMethod = method;
                removedChildId = args['deviceId'] as String?;
                return ProjectSnapshot(
                  bpm: 120,
                  selectedTrackId: track.id,
                  playheadBeats: 0,
                  playing: false,
                  loopEnabled: true,
                  recordArmed: false,
                  master: const MasterTrackSnapshot(
                    id: 'master',
                    name: 'Master',
                    gain: 1.0,
                  ),
                  samples: const [],
                  tracks: [track],
                  lfos: const [],
                  modEdges: const [],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final deleteButtons = find.byIcon(Icons.delete_outline);
    expect(deleteButtons, findsNWidgets(2));

    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    expect(removeMethod, 'removeDeviceFromChain');
    expect(removedChildId, 'chain-child-2');
  });
}
