import 'package:audioapp/bridge/clip_snapshots.dart';
import 'package:audioapp/bridge/timeline_clip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MidiClipSnapshot implements ClipTimelineSpan', () {
    const clip = MidiClipSnapshot(
      id: 'clip-1',
      startBeat: 4.0,
      lengthBeats: 8.0,
      notes: [],
    );
    expect(clip.kind, ClipContentKind.midi);
    expect(clip.endBeat, 12.0);
  });

  test('SampleClipSnapshot implements ClipTimelineSpan', () {
    const clip = SampleClipSnapshot(
      id: 's-1',
      sampleId: 'kick',
      sampleName: 'Kick',
      startBeat: 0.0,
      lengthBeats: 2.0,
      waveformPeaks: [0.5, 0.8],
    );
    expect(clip.kind, ClipContentKind.sample);
    expect(clip.endBeat, 2.0);
  });
}
