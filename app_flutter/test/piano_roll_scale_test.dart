import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/piano_roll/piano_roll_scale.dart';
import 'package:audioapp/features/play/play_deck_layout.dart';
import 'package:audioapp/features/play/play_scale.dart';

void main() {
  test('snaps out-of-scale pitches to nearest scale pitch', () {
    const settings = PianoRollScaleSettings(snapToScale: true);

    expect(settings.snapPitch(61, minPitch: 48, maxPitch: 72), 62);
    expect(settings.snapPitch(62, minPitch: 48, maxPitch: 72), 62);
  });

  test('chord painter expands selected quality from snapped root', () {
    const settings = PianoRollScaleSettings(
      scale: PlayScale.major,
      snapToScale: true,
      chordQuality: ChordQuality.minor,
    );

    expect(
      settings.chordPitches(61, minPitch: 48, maxPitch: 72),
      [62, 65, 69],
    );
  });

  test('restores scale settings from midi clip metadata', () {
    const clip = MidiClipSnapshot(
      id: 'clip-a',
      startBeat: 0,
      lengthBeats: 4,
      editorScaleRoot: 2,
      editorScaleId: 'minor',
      editorScaleHighlight: true,
      editorScaleSnap: true,
      editorChordQuality: 'sus4',
      notes: [],
    );

    final settings = PianoRollScaleSettings.fromClip(clip);

    expect(settings.rootPitchClass, 2);
    expect(settings.scale, PlayScale.minor);
    expect(settings.highlight, isTrue);
    expect(settings.snapToScale, isTrue);
    expect(settings.chordQuality, ChordQuality.sus4);
  });

  test('legacy clips leave scale tools off', () {
    const clip = MidiClipSnapshot(
      id: 'clip-a',
      startBeat: 0,
      lengthBeats: 4,
      notes: [],
    );

    final settings = PianoRollScaleSettings.fromClip(clip);

    expect(settings.highlight, isFalse);
    expect(settings.snapToScale, isFalse);
  });
}
