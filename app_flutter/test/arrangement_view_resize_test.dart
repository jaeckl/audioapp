import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/arrangement/arrangement_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The resize handle is rendered as a sibling Positioned in the track lane
// (see arrangement_view.dart). At rest the handle's *visual* 12 px bar sits
// flush on the right edge of the rendered clip:
//   left = startBeat*ppb + renderedClipWidthPx - kResizeHandleHitWidth
// The hit zone is kResizeHandleHitWidth = 44 px (right-aligned in the
// Positioned) so users get a forgiving touch target.
//
// pixelsPerBeat defaults to 64.0.

const double _kResizeHandleHitWidth = 44.0;

ProjectSnapshot _baseSnapshot({
  List<TrackSnapshot> Function() tracksBuilder = _threeTracksAllClips,
}) {
  return ProjectSnapshot(
    bpm: 120,
    playheadBeats: 0,
    playing: false,
    loopEnabled: false,
    loopRegionStartBeat: 0,
    loopRegionEndBeat: 16,
    recordArmed: false,
    selectedTrackId: 'track-midi',
    master: const MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
    tracks: tracksBuilder(),
    samples: const [],
  );
}

List<TrackSnapshot> _threeTracksAllClips() => [
  const TrackSnapshot(
    id: 'track-midi',
    name: 'MIDI Track',
    devices: [],
    midiClips: [
      MidiClipSnapshot(
        id: 'midi-clip-1', startBeat: 0, lengthBeats: 4, notes: [],
      ),
    ],
    sampleClips: [],
    automationClips: [],
  ),
  const TrackSnapshot(
    id: 'track-sample',
    name: 'Sample Track',
    devices: [],
    midiClips: [],
    sampleClips: [
      SampleClipSnapshot(
        id: 'sample-clip-1', sampleId: 'sample-1', sampleName: 'Kick',
        startBeat: 0, lengthBeats: 4, waveformPeaks: [],
      ),
    ],
    automationClips: [],
  ),
  const TrackSnapshot(
    id: 'track-auto',
    name: 'Automation Track',
    devices: [],
    midiClips: [],
    sampleClips: [],
    automationClips: [
      AutomationClipSnapshot(
        id: 'auto-clip-1', homeTrackId: 'track-auto',
        startBeat: 0, lengthBeats: 4, deviceId: '', paramId: '', points: [],
      ),
    ],
  ),
];

List<TrackSnapshot> _twoAdjacentMidiClips() => [
  const TrackSnapshot(
    id: 'track-midi',
    name: 'MIDI Track',
    devices: [],
    midiClips: [
      MidiClipSnapshot(id: 'midi-clip-1', startBeat: 0, lengthBeats: 4, notes: []),
      MidiClipSnapshot(id: 'midi-clip-2', startBeat: 8, lengthBeats: 4, notes: []),
    ],
    sampleClips: [],
    automationClips: [],
  ),
];

class _CommitLog {
  final List<({String clipId, double lengthBeats})> commits = [];

  Future<void> record({
    required String clipId,
    required double lengthBeats,
  }) async {
    commits.add((clipId: clipId, lengthBeats: lengthBeats));
  }
}

Future<_CommitLog> _pumpArrangement(
  WidgetTester tester, {
  required ProjectSnapshot snapshot,
  double width = 1600,
  double height = 1200,
}) async {
  final log = _CommitLog();

  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
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
          onLoopRegionChanged: ({required startBeat, required endBeat}) async {},
          onClipTap: (_, __) {},
          onSampleClipTap: (_, __) {},
          onMoveClip: ({
            required clipId,
            required trackId,
            required startBeat,
          }) async {},
          onResizeClipCommit: log.record,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return log;
}

/// Track order: midi first, then sample, then automation. Within each track
/// the resize handles are added in a flat list with sample → midi → automation
/// order per track, then track order. With our 3-track setup of one clip each
/// the handles in tree order are: midi-clip-1, sample-clip-1, auto-clip-1.
int _handleIndexFor(String clipId) {
  switch (clipId) {
    case 'midi-clip-1':
      return 0;
    case 'sample-clip-1':
      return 1;
    case 'auto-clip-1':
      return 2;
    default:
      throw ArgumentError('Unknown clip id: $clipId');
  }
}

Finder _handleFinder(String clipId) {
  final list = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_ClipResizeHandle');
  final idx = _handleIndexFor(clipId);
  return list.at(idx);
}

Finder _handleGestureFinder(String clipId) {
  final handle = _handleFinder(clipId);
  return find.descendant(of: handle, matching: find.byType(GestureDetector));
}

/// Locate the Positioned widget that wraps the resize handle of [clipId].
/// The handle widget itself sits inside a Positioned in the track-lane Stack,
/// so we look up the ancestor chain.
Finder _handlePositioned(String clipId) {
  final handle = _handleFinder(clipId);
  return find.ancestor(of: handle, matching: find.byType(Positioned));
}

/// Find the clip-block Positioned (outer container that wraps the rendered
/// clip content). It has width == lengthBeats * pixelsPerBeat (MIDI/auto)
/// or the zoom-aware clipDisplayWidthPx (sample) and never stretches during
/// a resize.
Finder _clipBlockPositioned(String clipId, {required double widthPx}) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Positioned) return false;
    if (widget.width != widthPx) return false;
    // The resize-handle Positioned uses hit width (28 px), so the width
    // comparison alone disambiguates clip blocks from handles. We still
    // exclude handle-sized widths as a defensive guard.
    return widget.width != _kResizeHandleHitWidth;
  });
}

GestureDetector _handleGesture(WidgetTester tester, String clipId) {
  final gestureFinder = _handleGestureFinder(clipId);
  return tester.widget<GestureDetector>(gestureFinder);
}

Offset _handleOrigin(WidgetTester tester, String clipId) {
  return tester.getTopLeft(_handleGestureFinder(clipId));
}

void _triggerStart(WidgetTester tester, String clipId) {
  _handleGesture(tester, clipId).onHorizontalDragStart!(
    DragStartDetails(globalPosition: _handleOrigin(tester, clipId)),
  );
}

void _triggerMove(WidgetTester tester, String clipId, Offset delta) {
  final origin = _handleOrigin(tester, clipId);
  _handleGesture(tester, clipId).onHorizontalDragUpdate!(
    DragUpdateDetails(
      globalPosition: origin + delta,
      delta: delta,
    ),
  );
}

void _triggerEnd(WidgetTester tester, String clipId) {
  _handleGesture(tester, clipId).onHorizontalDragEnd!(
    DragEndDetails(),
  );
}

void _triggerCancel(WidgetTester tester, String clipId) {
  _handleGesture(tester, clipId).onHorizontalDragCancel!();
}

/// Reads the `left` property of the resize handle's outer Positioned.
double _handleLeft(WidgetTester tester, String clipId) {
  final positioned = tester.widget<Positioned>(_handlePositioned(clipId));
  return positioned.left ?? 0;
}

void main() {
  testWidgets('F1: ResizeHandleRendered — three handles, one per clip',
      (tester) async {
    await _pumpArrangement(tester, snapshot: _baseSnapshot());

    expect(find.bySemanticsLabel('Resize clip'), findsNWidgets(3));
  });

  testWidgets('F2: DragRightIncreasesLength — handle moves to preview x',
      (tester) async {
    await _pumpArrangement(tester, snapshot: _baseSnapshot());

    // Initial: Positioned is 44 px wide and its right edge sits on the
    // rendered right edge of the clip. The 12 px visual bar then anchors
    // to the right of the 44 px zone via [Align.centerRight] inside the
    // handle widget.
    //   Positioned.left = startBeat*ppb + 256 - 44 = 212 px.
    expect(_handleLeft(tester, 'midi-clip-1'), 212.0);

    _triggerStart(tester, 'midi-clip-1');
    await tester.pump();

    // Drag right 128 px (= 2 beats).
    _triggerMove(tester, 'midi-clip-1', const Offset(128, 0));
    await tester.pump();

    // Handle now at 0 + 384 - 44 = 340 px.
    expect(_handleLeft(tester, 'midi-clip-1'), 340.0);

    // The clip block being resized live resizes to 384 px. The other two stay at 256 px.
    expect(
      _clipBlockPositioned('midi-clip-1', widthPx: 384),
      findsOneWidget,
      reason: 'The MIDI clip being resized live resizes to 384 px',
    );
    expect(
      _clipBlockPositioned('midi-clip-1', widthPx: 256),
      findsNWidgets(2),
      reason: 'The other two clips stay at 256 px',
    );
  });

  testWidgets('F3: DragLeftDecreasesLength — handle moves to preview x',
      (tester) async {
    await _pumpArrangement(tester, snapshot: _baseSnapshot());

    _triggerStart(tester, 'midi-clip-1');
    await tester.pump();

    // Drag left 64 px (= 1 beat).
    _triggerMove(tester, 'midi-clip-1', const Offset(-64, 0));
    await tester.pump();

    // Handle at 0 + 192 - 44 = 148 px.
    expect(_handleLeft(tester, 'midi-clip-1'), 148.0);
  });

  testWidgets('F4: NoBeatGridSnap — drag 1.25 beats keeps fractional length',
      (tester) async {
    await _pumpArrangement(tester, snapshot: _baseSnapshot());

    _triggerStart(tester, 'midi-clip-1');
    await tester.pump();

    // Drag right 80 px (= 1.25 beats) → 5.25 beats total (no grid snap).
    _triggerMove(tester, 'midi-clip-1', const Offset(80, 0));
    await tester.pump();

    // Handle at 0 + 336 - 44 = 292 px (5.25 beats, not snapped to 5.0).
    expect(_handleLeft(tester, 'midi-clip-1'), 292.0);
  });

  testWidgets('F5: ClampsToMinimumLength — drag left until timeline origin',
      (tester) async {
    await _pumpArrangement(tester, snapshot: _baseSnapshot());

    _triggerStart(tester, 'midi-clip-1');
    await tester.pump();

    // Drag left 300 px from handle origin (~beat 3.3125). Pointer clamps to
    // beat 0 → length 0.6875 beats (handle hit zone, not kMinClipLengthBeats).
    _triggerMove(tester, 'midi-clip-1', const Offset(-300, 0));
    await tester.pump();

    expect(_handleLeft(tester, 'midi-clip-1'), 0.0);
  });

  testWidgets('F6: ClampsToAdjacentClip — second clip at 8, clamps to 8.0',
      (tester) async {
    await _pumpArrangement(
      tester,
      snapshot: _baseSnapshot(tracksBuilder: _twoAdjacentMidiClips),
    );

    _triggerStart(tester, 'midi-clip-1');
    await tester.pump();

    // Drag far right — 500 px (= 7.8125 beats). max = 8 - 0 = 8 beats.
    _triggerMove(tester, 'midi-clip-1', const Offset(500, 0));
    await tester.pump();

    // Handle at 0 + 512 - 44 = 468 px.
    expect(_handleLeft(tester, 'midi-clip-1'), 468.0);
  });

  testWidgets('F7: CommitsCorrectLength — release commits (clipId, 6.0)',
      (tester) async {
    final log = await _pumpArrangement(tester, snapshot: _baseSnapshot());

    _triggerStart(tester, 'midi-clip-1');
    await tester.pump();

    _triggerMove(tester, 'midi-clip-1', const Offset(128, 0));
    await tester.pump();

    _triggerEnd(tester, 'midi-clip-1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(log.commits.length, 1);
    expect(log.commits.first.clipId, 'midi-clip-1');
    expect(log.commits.first.lengthBeats, 6.0);
  });

  testWidgets('F8: CancelRevertsLength — handle returns to original position',
      (tester) async {
    final log = await _pumpArrangement(tester, snapshot: _baseSnapshot());

    // Initial handle at 212 px.
    expect(_handleLeft(tester, 'midi-clip-1'), 212.0);

    _triggerStart(tester, 'midi-clip-1');
    await tester.pump();

    _triggerMove(tester, 'midi-clip-1', const Offset(128, 0));
    await tester.pump();

    expect(_handleLeft(tester, 'midi-clip-1'), 340.0);

    _triggerCancel(tester, 'midi-clip-1');
    await tester.pump();

    expect(log.commits, isEmpty);

    // Handle reverts to original position 212 px.
    expect(_handleLeft(tester, 'midi-clip-1'), 212.0);
  });

  testWidgets('F9: ResizeDoesNotTriggerClipDrag — resize-only commit fires',
      (tester) async {
    final log = await _pumpArrangement(tester, snapshot: _baseSnapshot());

    _triggerStart(tester, 'midi-clip-1');
    await tester.pump();

    _triggerMove(tester, 'midi-clip-1', const Offset(64, 0));
    await tester.pump();

    _triggerEnd(tester, 'midi-clip-1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(log.commits.length, 1);
    expect(log.commits.first.clipId, 'midi-clip-1');
    expect(log.commits.first.lengthBeats, 5.0);
  });

  testWidgets('F10: AutomationClipResize — handle moves + commits',
      (tester) async {
    final log = await _pumpArrangement(tester, snapshot: _baseSnapshot());

    _triggerStart(tester, 'auto-clip-1');
    await tester.pump();

    _triggerMove(tester, 'auto-clip-1', const Offset(128, 0));
    await tester.pump();

    expect(_handleLeft(tester, 'auto-clip-1'), 340.0);

    _triggerEnd(tester, 'auto-clip-1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(log.commits.length, 1);
    expect(log.commits.first.clipId, 'auto-clip-1');
    expect(log.commits.first.lengthBeats, 6.0);
  });

  testWidgets('F11: SampleClipResize — handle moves + commits',
      (tester) async {
    final log = await _pumpArrangement(tester, snapshot: _baseSnapshot());

    _triggerStart(tester, 'sample-clip-1');
    await tester.pump();

    _triggerMove(tester, 'sample-clip-1', const Offset(64, 0));
    await tester.pump();

    // Sample rendered width at ppb=64, viewport=1600, lengthBeats=4
    // = clipDisplayWidthPx = 256. Handle at 0 + 320 - 44 = 276 px.
    expect(_handleLeft(tester, 'sample-clip-1'), 276.0);

    _triggerEnd(tester, 'sample-clip-1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(log.commits.length, 1);
    expect(log.commits.first.clipId, 'sample-clip-1');
    expect(log.commits.first.lengthBeats, 5.0);
  });
}