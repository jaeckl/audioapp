import 'package:audioapp/bridge/live_meters_dto.dart';
import 'package:audioapp/bridge/live_meters_store.dart';
import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/mixer/mixer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    const snapshot = ProjectSnapshot(
      bpm: 120,
      selectedTrackId: 'track-1',
      playheadBeats: 0,
      playing: false,
      loopEnabled: false,
      recordArmed: false,
      master: MasterTrackSnapshot(id: 'master', name: 'Master', gain: .8),
      samples: [],
      tracks: [
        TrackSnapshot(
          id: 'track-1',
          name: 'Lead',
          devices: [
            TrackGainDeviceSnapshot(
              id: 'gain-1',
              gain: .75,
              pan: .25,
              bypassed: false,
              meterGainReductionDb: 0,
              meterInputLevel: 0,
            ),
          ],
          midiClips: [],
          sampleClips: [],
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MixerView(
          snapshot: snapshot,
          liveMeters: meters,
          onTrackGainChanged: (_, __) {},
          onTrackPanChanged: (_, __) {},
          onTrackMuted: (_, __) {},
          onTrackSoloed: (_, __) {},
          onTrackSelected: (_) {},
          onMasterGainChanged: (_) {},
        ),
      ),
    ));
    expect(find.text('Lead'), findsOneWidget);
    expect(find.text('Pan'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('Master'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
