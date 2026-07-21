import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_chain_row.dart';
import 'package:audioapp/features/device_strip/device_chain_separator.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:audioapp/features/device_strip/device_tool_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _track = TrackSnapshot(
  id: 'track-1',
  name: 'Devices',
  devices: [
    DeviceSnapshot(
      id: 'dev-a',
      type: 'simple_oscillator',
      bypassed: false,
      parameters: {},
    ),
    DeviceSnapshot(
      id: 'dev-b',
      type: 'compressor',
      bypassed: false,
      parameters: {},
    ),
    DeviceSnapshot(
      id: 'dev-c',
      type: 'delay',
      bypassed: false,
      parameters: {},
    ),
    TrackGainDeviceSnapshot(
      id: 'dev-gain',
      type: 'track_gain',
      bypassed: false,
      parameters: {'gain': 1.0},
      gain: 1.0,
      pan: 0.5,
    ),
  ],
  midiClips: [],
  sampleClips: [],
);

Future<void> _dragToolRail(
  WidgetTester tester, {
  required Finder source,
  required Offset destination,
}) async {
  final box = tester.renderObject<RenderBox>(source);
  final start =
      box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 650));
  for (var step = 1; step <= 8; step++) {
    await gesture.moveTo(Offset.lerp(start, destination, step / 8)!);
    await tester.pump(const Duration(milliseconds: 20));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('long-press tool rail and drop on separator reorders device',
      (tester) async {
    final moves = <({String deviceId, int toIndex})>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 280,
            width: 900,
            child: DeviceChainRow(
              track: _track,
              samples: const [],
              playing: false,
              bpm: 120,
              density: DeviceStripSlotDensity.strip,
              onSamplerParameterChanged: (_, __, ___) {},
              onOpenSamplerEditor: (_, __) {},
              onFrequencyChanged: (_, __) {},
              onInsertDevice: (_) async => null,
              onMoveDevice: (deviceId, toIndex) async {
                moves.add((deviceId: deviceId, toIndex: toIndex));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final separators = find.byType(DeviceChainSeparator);
    expect(separators, findsNWidgets(3));

    final lastSeparator = tester.getCenter(separators.at(2));
    await _dragToolRail(
      tester,
      source: find.byType(DeviceToolRail).first,
      destination: lastSeparator,
    );

    expect(moves, [(deviceId: 'dev-a', toIndex: 3)]);
  });
}
