import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/arrangement/arrangement_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _snapshot = ProjectSnapshot(
  bpm: 120,
  selectedTrackId: 'loose',
  playheadBeats: 0,
  playing: false,
  loopEnabled: false,
  recordArmed: false,
  master: MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
  samples: [],
  tracks: [
    TrackSnapshot(
      id: 'bus',
      name: 'Bus',
      isGroup: true,
      devices: [],
      midiClips: [],
      sampleClips: [],
    ),
    TrackSnapshot(
      id: 'child-a',
      name: 'Child A',
      parentGroupId: 'bus',
      devices: [],
      midiClips: [],
      sampleClips: [],
    ),
    TrackSnapshot(
      id: 'child-b',
      name: 'Child B',
      parentGroupId: 'bus',
      devices: [],
      midiClips: [],
      sampleClips: [],
    ),
    TrackSnapshot(
      id: 'loose',
      name: 'Loose',
      devices: [],
      midiClips: [],
      sampleClips: [],
    ),
  ],
);

ProjectSnapshot _manyTracksSnapshot() => ProjectSnapshot(
      bpm: 120,
      selectedTrackId: 'track-1',
      playheadBeats: 0,
      playing: false,
      loopEnabled: false,
      recordArmed: false,
      master: const MasterTrackSnapshot(
        id: 'master',
        name: 'Master',
        gain: 1,
      ),
      samples: const [],
      tracks: [
        for (var index = 1; index <= 12; index++)
          TrackSnapshot(
            id: 'track-$index',
            name: 'Track $index',
            iconKey: index.isEven ? 'audio' : 'piano',
            devices: const [],
            midiClips: const [],
            sampleClips: const [],
          ),
      ],
    );

typedef _Move = ({String trackId, String parentGroupId, String beforeTrackId});

Future<List<_Move>> _pumpArrangement(
  WidgetTester tester, {
  ProjectSnapshot snapshot = _snapshot,
}) async {
  final moves = <_Move>[];
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ArrangementView(
          snapshot: snapshot,
          onTrackSelected: (_) {},
          onAddTrack: () {},
          onAddMidiClip: (_, __) {},
          onAddAudioClip: (_, __) {},
          playheadBeats: 0,
          playing: false,
          onPlayRequested: () {},
          onStopRequested: () {},
          onPlayheadSeek: (_) {},
          onLoopRegionChanged: ({
            required startBeat,
            required endBeat,
          }) async {},
          onClipTap: (_, __) {},
          onSampleClipTap: (_, __) {},
          onMoveClip: ({
            required clipId,
            required trackId,
            required startBeat,
          }) async {},
          onMoveTrack: ({
            required trackId,
            required parentGroupId,
            required beforeTrackId,
          }) async {
            moves.add((
              trackId: trackId,
              parentGroupId: parentGroupId,
              beforeTrackId: beforeTrackId,
            ));
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return moves;
}

Future<void> _dragHeader(
  WidgetTester tester, {
  required String source,
  required Offset destination,
}) async {
  final start = tester.getCenter(find.byTooltip(source));
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 650));
  expect(find.text(source), findsOneWidget,
      reason: 'drag feedback should appear');
  for (var step = 1; step <= 8; step++) {
    await gesture.moveTo(Offset.lerp(start, destination, step / 8)!);
    await tester.pump(const Duration(milliseconds: 20));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dropping a track on a group appends it', (tester) async {
    final moves = await _pumpArrangement(tester);
    await _dragHeader(
      tester,
      source: 'Loose',
      destination: tester.getCenter(find.byTooltip('Bus')),
    );

    expect(
      moves,
      [(trackId: 'loose', parentGroupId: 'bus', beforeTrackId: '')],
    );
  });

  testWidgets('dropping before a top-level track removes grouping',
      (tester) async {
    final moves = await _pumpArrangement(tester);
    final looseRect = tester.getRect(find.byTooltip('Loose'));
    await _dragHeader(
      tester,
      source: 'Child A',
      destination: Offset(looseRect.center.dx, looseRect.top + 3),
    );

    expect(
      moves,
      [(trackId: 'child-a', parentGroupId: '', beforeTrackId: 'loose')],
    );
  });

  testWidgets('dropping after a child reorders within its group',
      (tester) async {
    final moves = await _pumpArrangement(tester);
    final childRect = tester.getRect(find.byTooltip('Child B'));
    await _dragHeader(
      tester,
      source: 'Child A',
      destination: Offset(childRect.center.dx, childRect.bottom - 3),
    );

    expect(
      moves,
      [(trackId: 'child-a', parentGroupId: 'bus', beforeTrackId: '')],
    );
  });

  testWidgets('dragging a group keeps it at top level', (tester) async {
    final moves = await _pumpArrangement(tester);
    final looseRect = tester.getRect(find.byTooltip('Loose'));
    await _dragHeader(
      tester,
      source: 'Bus',
      destination: Offset(looseRect.center.dx, looseRect.bottom - 3),
    );

    expect(
      moves,
      [(trackId: 'bus', parentGroupId: '', beforeTrackId: '')],
    );
  });

  testWidgets('track lanes and headers scroll vertically above pinned master',
      (tester) async {
    await _pumpArrangement(tester, snapshot: _manyTracksSnapshot());
    final masterBefore = tester.getRect(find.byTooltip('Master'));
    expect(find.byTooltip('Track 12').hitTestable(), findsNothing);

    await tester.dragFrom(const Offset(300, 260), const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Track 12').hitTestable(), findsOneWidget);
    expect(tester.getRect(find.byTooltip('Master')), masterBefore);
  });

  testWidgets('track drag auto-scrolls near the bottom edge', (tester) async {
    await _pumpArrangement(tester, snapshot: _manyTracksSnapshot());
    final start = tester.getCenter(find.byTooltip('Track 1'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 650));

    for (var step = 0; step < 12; step++) {
      await gesture.moveTo(Offset(22, step.isEven ? 610 : 620));
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.byTooltip('Track 12').hitTestable(), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
