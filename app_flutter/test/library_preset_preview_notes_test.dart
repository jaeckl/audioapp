import 'package:audioapp/bridge/clip_snapshots.dart';
import 'package:audioapp/features/content_library/factory_preset_json.dart';
import 'package:audioapp/features/content_library/library_preset_preview_notes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arrangement MIDI notes are preferred over demo arpeggio', () {
    final clips = [
      MidiClipSnapshot(
        id: 'c1',
        startBeat: 4.0,
        lengthBeats: 4.0,
        notes: const [
          MidiNoteSnapshot(
              pitch: 36, startBeat: 0.0, durationBeats: 0.5, velocity: 100),
          MidiNoteSnapshot(
              pitch: 48, startBeat: 1.0, durationBeats: 0.5, velocity: 80),
        ],
      ),
    ];
    final notes = libraryPresetPreviewNotesFromClips(clips);
    expect(notes, isNotEmpty);
    expect(notes.first.pitch, 36);
    expect(notes.first.startBeat, 4.0);
    expect(notes[1].startBeat, 5.0);
    // Loop end 16 wins over clip end 8.
    expect(
      libraryPresetPreviewLengthBeats(clips, loopRegionEndBeat: 16.0),
      16.0,
    );
    // Track past loop still extends length.
    expect(
      libraryPresetPreviewLengthBeats(clips, loopRegionEndBeat: 4.0),
      8.0,
    );
  });

  test('looped clip content tiles notes across clip span', () {
    final clips = [
      MidiClipSnapshot(
        id: 'c1',
        startBeat: 0.0,
        lengthBeats: 8.0,
        naturalLengthBeats: 2.0,
        loopContent: true,
        notes: const [
          MidiNoteSnapshot(
              pitch: 60, startBeat: 0.0, durationBeats: 0.5, velocity: 100),
        ],
      ),
    ];
    final notes = libraryPresetPreviewNotesFromClips(clips);
    expect(notes.map((n) => n.startBeat).toList(), [0.0, 2.0, 4.0, 6.0]);
  });

  test('empty clips yield empty note list for demo fallback', () {
    expect(libraryPresetPreviewNotesFromClips(const []), isEmpty);
    expect(libraryPresetDemoArpeggio.length, 4);
  });

  test('FX device types do not claim audio preview', () {
    expect(FactoryPresetJson.supportsAudioPreview('compressor'), isFalse);
    expect(FactoryPresetJson.supportsAudioPreview('delay'), isFalse);
    expect(FactoryPresetJson.supportsAudioPreview('subtractive_synth'), isTrue);
    expect(FactoryPresetJson.supportsAudioPreview('bass_synth'), isTrue);
    expect(FactoryPresetJson.supportsAudioPreview('phase_mod_synth'), isTrue);
    expect(FactoryPresetJson.supportsAudioPreview('kick_generator'), isTrue);
  });
}
