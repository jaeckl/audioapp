import 'dart:ui';

import 'package:audioapp/features/arrangement/arrangement_clip_beat_layout.dart';
import 'package:audioapp/features/arrangement/clip_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('beatToX aligns clip beats with arrangement grid spacing', () {
    const lengthBeats = 16.0;
    const pixelsPerBeat = 64.0;
    const contentRect = Rect.fromLTWH(0, 0, lengthBeats * pixelsPerBeat - 6, 40);

    expect(
      ArrangementClipBeatLayout.pixelsPerBeat(
        contentRect: contentRect,
        lengthBeats: lengthBeats,
      ),
      pixelsPerBeat,
    );
    expect(
      ArrangementClipBeatLayout.beatToX(
        beat: 0,
        contentRect: contentRect,
        lengthBeats: lengthBeats,
      ),
      -ArrangementClipChrome.contentInset,
    );
    expect(
      ArrangementClipBeatLayout.beatToX(
        beat: 4,
        contentRect: contentRect,
        lengthBeats: lengthBeats,
      ),
      4 * pixelsPerBeat - ArrangementClipChrome.contentInset,
    );
    expect(
      ArrangementClipBeatLayout.beatToX(
        beat: lengthBeats,
        contentRect: contentRect,
        lengthBeats: lengthBeats,
      ),
      lengthBeats * pixelsPerBeat - ArrangementClipChrome.contentInset,
    );
  });
}
