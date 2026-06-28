import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/arrangement/arrangement_timeline_metrics.dart';
import 'package:audioapp/features/arrangement/arrangement_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _snapshot = ProjectSnapshot(
  bpm: 120,
  selectedTrackId: 'track-1',
  playheadBeats: 0,
  playing: false,
  loopEnabled: false,
  recordArmed: false,
  master: MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
  samples: const [],
  tracks: [
    TrackSnapshot(
      id: 'track-1',
      name: 'Kick',
      iconKey: 'audio',
      devices: const [],
      midiClips: const [],
      sampleClips: const [],
    ),
    TrackSnapshot(
      id: 'track-2',
      name: 'Snare',
      muted: true,
      devices: const [],
      midiClips: const [],
      sampleClips: const [],
    ),
  ],
);

Future<void> _pumpArrangement(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ArrangementView(
          snapshot: _snapshot,
          onTrackSelected: (_) {},
          onAddTrack: () {},
          onAddMidiClip: (_, __) {},
          onAddAudioClip: (_, __) {},
          playheadBeats: 0,
          playing: false,
          onPlayRequested: () {},
          onStopRequested: () {},
          onPlayheadSeek: (_) {},
          onLoopRegionChanged: ({required startBeat, required endBeat}) async {},
          onClipTap: (_, __) {},
          onSampleClipTap: (_, __) {},
          onMoveClip: ({
            required clipId,
            required trackId,
            required startBeat,
          }) async {},
          onSetTrackMuted: ({required trackId, required muted}) async {},
          onSetTrackSoloed: ({required trackId, required soloed}) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('expanded header shows title and mix controls', (tester) async {
    await _pumpArrangement(tester);

    expect(find.text('Kick'), findsNothing);

    final handle = find.byKey(const Key('trackHeaderColumnResize'));
    final center = tester.getCenter(handle);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(140, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Kick'), findsOneWidget);
    expect(find.text('Snare'), findsOneWidget);
    expect(find.text('S'), findsNWidgets(2));
    expect(find.text('M'), findsNWidgets(2));
  });

  test('header width metrics expose expanded threshold', () {
    expect(
      ArrangementTimelineMetrics.headerShowsMixControls(
        ArrangementTimelineMetrics.trackHeaderWidth,
      ),
      isFalse,
    );
    expect(
      ArrangementTimelineMetrics.headerShowsMixControls(
        ArrangementTimelineMetrics.trackHeaderExpandedWidth,
      ),
      isTrue,
    );
  });
}
