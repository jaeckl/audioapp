import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/device_strip/device_chain_row.dart';
import 'package:audioapp/features/device_strip/device_chain_separator.dart';
import 'package:audioapp/features/device_strip/device_drag_data.dart';
import 'package:audioapp/features/device_strip/device_strip_slot.dart';
import 'package:audioapp/features/device_strip/device_tool_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _dragData = DeviceDragData(
  trackId: 'track-1',
  deviceId: 'dev-a',
  deviceName: 'Compressor',
  deviceType: 'compressor',
  accentColor: Colors.orange,
  visibleIndex: 0,
  feedbackWidth: 280,
  feedbackHeight: 260,
);

const _track = TrackSnapshot(
  id: 'track-1',
  name: 'Devices',
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

void main() {
  testWidgets('tool rail middle grip starts long-press drag with snapshot',
      (tester) async {
    final repaintKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: SizedBox(
                width: 280,
                height: 260,
                child: ColoredBox(
                  color: const Color(0xFF2A2A35),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 260,
                        child: DeviceToolRail(
                          deviceName: 'Compressor',
                          accentColor: Colors.orange,
                          bypassed: false,
                          showLibrary: false,
                          onBypassToggle: _noop,
                          reorderDragData: _dragData,
                          reorderDragRepaintKey: repaintKey,
                        ),
                      ),
                      const Expanded(
                        child: Center(child: Text('DEVICE BODY')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final draggable = find.byType(LongPressDraggable<DeviceDragData>);
    expect(draggable, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(draggable));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('device-drag-feedback')), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    final feedback =
        tester.getSize(find.byKey(const ValueKey('device-drag-feedback')));
    expect(feedback.width, greaterThan(100));
    expect(feedback.height, greaterThan(100));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('chain row exposes reorder drag + drop targets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 280,
            width: 1200,
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
              onMoveDevice: (deviceId, toIndex) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LongPressDraggable<DeviceDragData>), findsWidgets);
    expect(find.byType(DeviceReorderDropTarget), findsWidgets);

    final draggable = find.byType(LongPressDraggable<DeviceDragData>).first;
    final gesture = await tester.startGesture(tester.getCenter(draggable));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('device-drag-feedback')), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('successful drop clears device gray-out', (tester) async {
    var track = _track;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 280,
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
                  onMoveDevice: (deviceId, toIndex) async {
                    final devices = List<DeviceSnapshot>.of(track.devices);
                    final from = devices.indexWhere((d) => d.id == deviceId);
                    if (from < 0) return;
                    final moved = devices.removeAt(from);
                    final insertAt = toIndex > from ? toIndex - 1 : toIndex;
                    devices.insert(insertAt.clamp(0, devices.length), moved);
                    setState(() {
                      track = TrackSnapshot(
                        id: track.id,
                        name: track.name,
                        devices: devices,
                        midiClips: track.midiClips,
                        sampleClips: track.sampleClips,
                      );
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final draggables = find.byType(LongPressDraggable<DeviceDragData>);
    expect(draggables, findsWidgets);
    final start = tester.getCenter(draggables.at(1));
    final drop = tester.getCenter(find.byType(DeviceReorderDropTarget).first);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byWidgetPredicate(
        (w) => w is Opacity && (w as Opacity).opacity == 0.18,
      ),
      findsOneWidget,
    );
    for (var step = 1; step <= 10; step++) {
      await gesture.moveTo(Offset.lerp(start, drop, step / 10)!);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) => w is Opacity && (w as Opacity).opacity == 0.18,
      ),
      findsNothing,
    );
  });
}

void _noop() {}
