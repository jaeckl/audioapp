import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_chain_separator.dart';
import 'package:audioapp/features/device_strip/device_drag_data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeviceReorderDropTarget accepts long-press drag', (tester) async {
    final moves = <({String deviceId, int toIndex})>[];
    const track = TrackSnapshot(
      id: 'track-1',
      name: 'T',
      devices: [
        CompressorDeviceSnapshot(
          id: 'dev-a',
          gain: 1,
          pan: 0.5,
          bypassed: false,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
          inputGain: 1,
          compThreshold: 0.55,
          compRatio: 0.5,
          compAttack: 0.2,
          compRelease: 0.55,
          compKnee: 0.25,
          compMakeup: 0.35,
        ),
        DelayDeviceSnapshot(
          id: 'dev-b',
          gain: 1,
          pan: 0.5,
          bypassed: false,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
          delayTimeMs: 250,
          delayFeedback: 0.4,
        ),
        TrackGainDeviceSnapshot(
          id: 'dev-gain',
          gain: 1,
          pan: 0.5,
          bypassed: false,
          meterGainReductionDb: 0,
          meterInputLevel: 0,
        ),
      ],
      midiClips: [],
      sampleClips: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              LongPressDraggable<DeviceDragData>(
                data: const DeviceDragData(
                  trackId: 'track-1',
                  deviceId: 'dev-a',
                  deviceName: 'A',
                  deviceType: 'compressor',
                  accentColor: Colors.red,
                  visibleIndex: 0,
                  feedbackWidth: 200,
                  feedbackHeight: 160,
                ),
                feedback: const SizedBox(
                  width: 40,
                  height: 40,
                  child: ColoredBox(color: Colors.red),
                ),
                child: const SizedBox(
                  width: 80,
                  height: 80,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
              DeviceReorderDropTarget(
                track: track,
                visibleInsertAfterIndex: 1,
                onMove: (deviceId, toIndex) async {
                  moves.add((deviceId: deviceId, toIndex: toIndex));
                },
                child: const SizedBox(
                  width: 80,
                  height: 80,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final start = tester.getCenter(find.byType(LongPressDraggable<DeviceDragData>));
    final end = tester.getCenter(find.byType(DeviceReorderDropTarget));
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    for (var step = 1; step <= 8; step++) {
      await gesture.moveTo(Offset.lerp(start, end, step / 8)!);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(moves, [(deviceId: 'dev-a', toIndex: 2)]);
  });
}
