import 'package:audioapp/features/editor/timeline_marker_layer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ppb = 50.0;
  const viewport = 400.0;
  const leadX = viewport * TimelineFollowMetrics.leadFraction; // 100

  test('timelineLeadViewportX uses lead fraction', () {
    expect(timelineLeadViewportX(400), leadX);
    expect(timelineLeadViewportX(200, leadFraction: 0.5), 100);
  });

  test('timelineScrollOffsetForBeatAtViewportX places beat at viewport X', () {
    expect(
      timelineScrollOffsetForBeatAtViewportX(
        beat: 4,
        pixelsPerBeat: ppb,
        viewportX: leadX,
      ),
      4 * ppb - leadX,
    );
    expect(
      timelineScrollOffsetForBeatAtViewportOrigin(beat: 2, pixelsPerBeat: ppb),
      2 * ppb,
    );
  });

  test('timelinePlayheadNeedsFollow inside follow zone', () {
    // Beat 2 at scroll 0 → natural X = 100 (lead margin).
    expect(
      timelinePlayheadNeedsFollow(
        beat: 2,
        pixelsPerBeat: ppb,
        scrollOffset: 0,
        viewportWidth: viewport,
      ),
      isFalse,
    );

    // Between lead and max — no follow.
    expect(
      timelinePlayheadNeedsFollow(
        beat: 4,
        pixelsPerBeat: ppb,
        scrollOffset: 100,
        viewportWidth: viewport,
      ),
      isFalse,
    );
  });

  test('timelinePlayheadNeedsFollow before lead or past max', () {
    // Playhead left of lead margin.
    expect(
      timelinePlayheadNeedsFollow(
        beat: 2,
        pixelsPerBeat: ppb,
        scrollOffset: 50,
        viewportWidth: viewport,
      ),
      isTrue,
    );

    // Playhead past right bound (natural > 340).
    expect(
      timelinePlayheadNeedsFollow(
        beat: 10,
        pixelsPerBeat: ppb,
        scrollOffset: 0,
        viewportWidth: viewport,
      ),
      isTrue,
    );
  });

  test('timelinePlayheadNeedsFollow ignores zero viewport', () {
    expect(
      timelinePlayheadNeedsFollow(
        beat: 8,
        pixelsPerBeat: ppb,
        scrollOffset: 0,
        viewportWidth: 0,
      ),
      isFalse,
    );
  });

  test('timelinePlayheadLoopedBackward detects loop wrap', () {
    expect(
      timelinePlayheadLoopedBackward(
        oldBeat: 15.9,
        newBeat: 0.1,
        loopEnabled: true,
      ),
      isTrue,
    );
    expect(
      timelinePlayheadLoopedBackward(
        oldBeat: 4.2,
        newBeat: 4.5,
        loopEnabled: true,
      ),
      isFalse,
    );
    expect(
      timelinePlayheadLoopedBackward(
        oldBeat: 15.9,
        newBeat: 0.1,
        loopEnabled: false,
      ),
      isFalse,
    );
  });
}
