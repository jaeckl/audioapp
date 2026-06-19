import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/arrangement/arrangement_timeline_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('short clip gets minimum readable width at default zoom', () {
    final width = ArrangementTimelineMetrics.clipDisplayWidthPx(
      startBeat: 0,
      lengthBeats: 0.5,
      pixelsPerBeat: ArrangementTimelineMetrics.defaultPixelsPerBeat,
      gapEndBeat: 16,
    );
    expect(width, greaterThanOrEqualTo(ArrangementTimelineMetrics.minClipDisplayWidthPx));
  });

  test('clip width does not exceed gap to next clip', () {
    final width = ArrangementTimelineMetrics.clipDisplayWidthPx(
      startBeat: 0,
      lengthBeats: 1,
      pixelsPerBeat: 48,
      gapEndBeat: 4,
    );
    expect(width, lessThanOrEqualTo(4 * 48));
  });

  test('viewport expands lone short clip', () {
    final width = ArrangementTimelineMetrics.clipDisplayWidthPx(
      startBeat: 0,
      lengthBeats: 0.25,
      pixelsPerBeat: ArrangementTimelineMetrics.defaultPixelsPerBeat,
      gapEndBeat: 32,
      viewportWidthPx: 300,
    );
    expect(width, greaterThan(16));
  });

  test('clip display width scales with horizontal zoom', () {
    const lengthBeats = 2.0;
    final narrow = ArrangementTimelineMetrics.clipDisplayWidthPx(
      startBeat: 0,
      lengthBeats: lengthBeats,
      pixelsPerBeat: 64,
      gapEndBeat: 32,
    );
    final wide = ArrangementTimelineMetrics.clipDisplayWidthPx(
      startBeat: 0,
      lengthBeats: lengthBeats,
      pixelsPerBeat: 128,
      gapEndBeat: 32,
    );
    expect(wide, closeTo(narrow * 2, 1));
  });

  test('gap end picks nearest clip start', () {
    final gap = ArrangementTimelineMetrics.gapEndBeatForClip(
      clipStartBeat: 0,
      otherClipStarts: [8, 4, 2],
      timelineEndBeat: 16,
    );
    expect(gap, 2);
  });

  test('quantizeBeat snaps down to grid', () {
    expect(ArrangementTimelineMetrics.quantizeBeat(3.9), 3.0);
    expect(ArrangementTimelineMetrics.quantizeBeat(4.0), 4.0);
  });

  test('placementStartBeat avoids overlap by shifting forward', () {
    final start = ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: 2.0,
      clipLengthBeats: 4.0,
      existingClips: [(start: 0.0, length: 4.0)],
    );
    expect(start, 4.0);
  });

  test('placementStartBeat uses quantized press position', () {
    final start = ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: 2.7,
      clipLengthBeats: 2.0,
      existingClips: [],
    );
    expect(start, 2.0);
  });

  test('virtualLengthBeats pads content like piano roll', () {
    const snapshot = ProjectSnapshot(
      bpm: 120,
      selectedTrackId: 'track-1',
      playheadBeats: 0,
      playing: false,
      loopEnabled: true,
      recordArmed: false,
      master: MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1),
      samples: [],
      tracks: [
        TrackSnapshot(
          id: 'track-1',
          name: 'Track 1',
          devices: const [],
          sampleClips: const [],
          automationClips: const [],
          midiClips: [
            MidiClipSnapshot(
              id: 'clip-1',
              startBeat: 0,
              lengthBeats: 4,
              notes: const [],
            ),
          ],
        ),
      ],
    );

    final virtual = ArrangementTimelineMetrics.virtualLengthBeats(snapshot);
    expect(virtual, greaterThanOrEqualTo(16 * 4));
    expect(
      ArrangementTimelineMetrics.rulerRegionEndBeat(snapshot),
      16,
    );
  });

  test('clipIntervalsForTrackExcluding omits moved clip', () {
    final track = TrackSnapshot(
      id: 'track-1',
      name: 'Track 1',
      devices: const [],
      sampleClips: const [],
      midiClips: [
        MidiClipSnapshot(
          id: 'clip-1',
          startBeat: 0,
          lengthBeats: 4,
          notes: const [],
        ),
        MidiClipSnapshot(
          id: 'clip-2',
          startBeat: 8,
          lengthBeats: 4,
          notes: const [],
        ),
      ],
    );

    final intervals = ArrangementTimelineMetrics.clipIntervalsForTrackExcluding(
      track,
      excludeClipId: 'clip-1',
    );
    expect(intervals.length, 1);
    expect(intervals.first.start, 8);
  });
}
