import 'package:audioapp/bridge/live_meters_dto.dart';
import 'package:audioapp/bridge/live_meters_store.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/mixer/mixer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectSnapshot _snapshot({
  double gain = 0.75,
  double pan = 0.25,
}) {
  return ProjectSnapshot(
    bpm: 120,
    selectedTrackId: 'track-1',
    playheadBeats: 0,
    playing: false,
    loopEnabled: false,
    recordArmed: false,
    master: const MasterTrackSnapshot(id: 'master', name: 'Master', gain: .8),
    samples: const [],
    tracks: [
      TrackSnapshot(
        id: 'track-1',
        name: 'Lead',
        devices: [
          TrackGainDeviceSnapshot(
            id: 'gain-1',
            gain: gain,
            pan: pan,
            bypassed: false,
            meterGainReductionDb: 0,
            meterInputLevel: 0,
          ),
        ],
        midiClips: const [],
        sampleClips: const [],
      ),
    ],
  );
}

Widget _harness({
  required ProjectSnapshot snapshot,
  required void Function(String, double) onGain,
  required void Function(String, double) onPan,
}) {
  final meters = LiveMetersStore();
  return MaterialApp(
    home: Scaffold(
      body: MixerView(
        snapshot: snapshot,
        liveMeters: meters,
        onTrackGainChanged: onGain,
        onTrackPanChanged: onPan,
        onTrackMuted: (_, __) {},
        onTrackSoloed: (_, __) {},
        onTrackRecordArmed: (_, __) {},
        onTrackSelected: (_) {},
        onMasterGainChanged: (_) {},
        onTrackOutputChanged: (_, __) {},
      ),
    ),
  );
}

void main() {
  test('stereo track meters parse independently', () {
    final meter = DeviceMeterReading.fromMap(
      {'in': .8, 'left': .7, 'right': .4},
      'gain-1',
    );
    expect(meter.leftLevel, .7);
    expect(meter.rightLevel, .4);
  });

  testWidgets('mixer renders channel controls and master', (tester) async {
    final meters = LiveMetersStore()
      ..applyBatch(const LiveMetersBatch(meters: [
        DeviceMeterReading(
          deviceId: 'gain-1',
          inputLevel: .8,
          leftLevel: .8,
          rightLevel: .5,
        ),
      ]));
    final snapshot = _snapshot();

    String? armedTrackId;
    bool? armedValue;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MixerView(
          snapshot: snapshot,
          liveMeters: meters,
          onTrackGainChanged: (_, __) {},
          onTrackPanChanged: (_, __) {},
          onTrackMuted: (_, __) {},
          onTrackSoloed: (_, __) {},
          onTrackRecordArmed: (trackId, armed) {
            armedTrackId = trackId;
            armedValue = armed;
          },
          onTrackSelected: (_) {},
          onMasterGainChanged: (_) {},
          onTrackOutputChanged: (_, __) {},
        ),
      ),
    ));

    expect(find.text('Lead'), findsOneWidget);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
    expect(find.byIcon(Icons.headphones), findsOneWidget);
    expect(find.byIcon(Icons.volume_off), findsWidgets);
    expect(find.text('Master'), findsWidgets);
    expect(find.text('Device'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.circle));
    await tester.pump();
    expect(armedTrackId, 'track-1');
    expect(armedValue, isTrue);

    expect(tester.takeException(), isNull);
  });

  testWidgets('double-tap pan resets to center', (tester) async {
    double? lastPan;
    String? lastDeviceId;
    var pan = 0.25;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return _harness(
            snapshot: _snapshot(pan: pan),
            onGain: (_, __) {},
            onPan: (deviceId, value) {
              lastDeviceId = deviceId;
              lastPan = value;
              setState(() => pan = value);
            },
          );
        },
      ),
    );

    expect(find.text('L50'), findsOneWidget);

    final hit = find.descendant(
      of: find.byKey(const ValueKey('mixer-pan-track-1')),
      matching: find.byType(Listener),
    );
    expect(hit, findsOneWidget);
    final box = tester.getRect(hit);
    // Tap near left so a single tap would NOT land on center.
    final target = Offset(box.left + 10, box.center.dy);

    await tester.tapAt(target);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(target);
    await tester.pump();

    expect(lastDeviceId, 'gain-1');
    expect(lastPan, 0.5);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('double-tap pan still resets after micro finger move',
      (tester) async {
    double? lastPan;

    await tester.pumpWidget(
      _harness(
        snapshot: _snapshot(pan: 0.8),
        onGain: (_, __) {},
        onPan: (_, value) => lastPan = value,
      ),
    );

    final hit = find.descendant(
      of: find.byKey(const ValueKey('mixer-pan-track-1')),
      matching: find.byType(Listener),
    );
    final center = tester.getCenter(hit);

    // First tap.
    final gesture1 = await tester.startGesture(center);
    await gesture1.up();
    await tester.pump(const Duration(milliseconds: 60));

    // Second tap + tiny move (the bug that used to overwrite reset).
    final gesture2 = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture2.moveBy(const Offset(3, 1));
    await gesture2.up();
    await tester.pump();

    expect(lastPan, 0.5);
  });

  testWidgets('drag pan still updates value', (tester) async {
    final pans = <double>[];

    await tester.pumpWidget(
      _harness(
        snapshot: _snapshot(pan: 0.5),
        onGain: (_, __) {},
        onPan: (_, value) => pans.add(value),
      ),
    );

    final hit = find.descendant(
      of: find.byKey(const ValueKey('mixer-pan-track-1')),
      matching: find.byType(Listener),
    );
    final box = tester.getRect(hit);
    final start = Offset(box.left + box.width * 0.5, box.center.dy);
    final end = Offset(box.left + box.width * 0.85, box.center.dy);

    await tester.dragFrom(start, end - start);
    await tester.pump();

    expect(pans, isNotEmpty);
    expect(pans.last, greaterThan(0.6));
  });

  testWidgets('double-tap gain resets to unity', (tester) async {
    double? lastGain;
    String? lastDeviceId;
    var gain = 0.4;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return _harness(
            snapshot: _snapshot(gain: gain, pan: 0.5),
            onGain: (deviceId, value) {
              lastDeviceId = deviceId;
              lastGain = value;
              setState(() => gain = value);
            },
            onPan: (_, __) {},
          );
        },
      ),
    );

    final hit = find.descendant(
      of: find.byKey(const ValueKey('mixer-gain-track-1')),
      matching: find.byType(Listener),
    );
    expect(hit, findsOneWidget);
    final box = tester.getRect(hit);
    // Tap near bottom so a single tap would NOT land on unity.
    final target = Offset(box.center.dx, box.bottom - 12);

    await tester.tapAt(target);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(target);
    await tester.pump();

    expect(lastDeviceId, 'gain-1');
    expect(lastGain, 1.0);
  });
}
