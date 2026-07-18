import 'package:flutter_test/flutter_test.dart';

import 'package:audioapp/bridge/project_snapshot.dart';
import 'package:audioapp/features/harmonic_assistant/chord_rhythm_catalog.dart';
import 'package:audioapp/features/harmonic_assistant/harmonic_assistant_commit.dart';
import 'package:audioapp/features/harmonic_assistant/harmonic_assistant_generator.dart';
import 'package:audioapp/features/harmonic_assistant/harmonic_assistant_spec.dart';
import 'package:audioapp/features/harmonic_assistant/harmonic_assistant_voicing.dart';
import 'package:audioapp/features/harmonic_assistant/harmonic_draft.dart';
import 'package:audioapp/features/harmonic_assistant/harmonic_note_ops.dart';
import 'package:audioapp/features/music_theory/chord_quality.dart';
import 'package:audioapp/features/music_theory/diatonic_harmony.dart';
import 'package:audioapp/features/music_theory/progression_templates.dart';
import 'package:audioapp/features/play/play_scale.dart';

void main() {
  group('DiatonicHarmony', () {
    test('C major palette roots and qualities', () {
      final palette = DiatonicHarmony.palette(
        scale: PlayScale.major,
        rootPitchClass: 0,
      );

      expect(palette.map((c) => c.rootPitchClass).toList(),
          [0, 2, 4, 5, 7, 9, 11]);
      expect(palette[0].quality, ChordQuality.major);
      expect(palette[1].quality, ChordQuality.minor);
      expect(palette[6].quality, ChordQuality.dim);
      expect(palette[0].label, 'I');
      expect(palette[6].label, 'vii°');
    });

    test('A minor palette', () {
      final palette = DiatonicHarmony.palette(
        scale: PlayScale.minor,
        rootPitchClass: 9,
      );
      expect(palette[0].rootPitchClass, 9);
      expect(palette[0].quality, ChordQuality.minor);
      expect(palette[4].quality, ChordQuality.minor);
      expect(palette[0].label, 'i');
    });
  });

  group('HarmonicAssistantVoicing', () {
    test('close C major near middle C', () {
      final pitches = HarmonicAssistantVoicing.pitches(
        rootPitchClass: 0,
        quality: ChordQuality.major,
        octaveCenter: 60,
        inversion: 0,
        width: HarmonicVoicingWidth.close,
      );
      expect(pitches, [60, 64, 67]);
    });

    test('first inversion raises bass', () {
      final pitches = HarmonicAssistantVoicing.pitches(
        rootPitchClass: 0,
        quality: ChordQuality.major,
        octaveCenter: 60,
        inversion: 1,
        width: HarmonicVoicingWidth.close,
      );
      expect(pitches.first, 64);
      expect(pitches, containsAll([64, 67, 72]));
    });
  });

  group('HarmonicAssistantGenerator', () {
    test('I–V–vi–IV block yields 12 notes over 16 beats', () {
      final spec = HarmonicAssistantSpec(
        scale: PlayScale.major,
        rootPitchClass: 0,
        degrees: ProgressionTemplate.pop1564.degrees,
        beatsPerChord: 4,
        rhythm: HarmonicRhythmPattern.block,
        inversion: 0,
        voiceLeadStrength: 0,
      );
      final notes = HarmonicAssistantGenerator.generate(spec);
      expect(notes.length, 12);
      expect(spec.totalBeats, 16);
      expect(notes.every((n) => n.startBeat < 16), isTrue);
      // I = C E G
      expect(
        notes.where((n) => n.startBeat == 0).map((n) => n.pitch).toList(),
        [60, 64, 67],
      );
    });

    test('draft with uneven block lengths', () {
      final draft = HarmonicDraft(
        scale: PlayScale.major,
        rootPitchClass: 0,
        blocks: const [
          HarmonicChordBlock(degree: 1, durationBeats: 2, inversion: 0),
          HarmonicChordBlock(degree: 5, durationBeats: 6, inversion: 0),
        ],
        voiceLeadStrength: 0,
      );
      final notes = HarmonicAssistantGenerator.generateDraft(draft);
      expect(draft.totalBeats, 8);
      expect(notes.where((n) => n.startBeat == 0).length, 3);
      expect(notes.where((n) => n.startBeat == 2).length, 3);
    });
  });

  group('HarmonicAssistantCommit', () {
    test('insert at playhead keeps existing notes', () {
      const existing = [
        MidiNoteSnapshot(
          pitch: 48,
          startBeat: 0,
          durationBeats: 1,
          velocity: 100,
        ),
      ];
      const generated = [
        MidiNoteSnapshot(
          pitch: 60,
          startBeat: 0,
          durationBeats: 2,
          velocity: 100,
        ),
      ];
      final merged = HarmonicAssistantCommit.merge(
        existing: existing,
        generated: generated,
        mode: HarmonicCommitMode.insertAtPlayhead,
        playheadBeat: 4,
      );
      expect(merged.length, 2);
      expect(merged.last.startBeat, 4);
    });

    test('replace range drops overlapping notes', () {
      const existing = [
        MidiNoteSnapshot(
          pitch: 48,
          startBeat: 0,
          durationBeats: 2,
          velocity: 100,
        ),
        MidiNoteSnapshot(
          pitch: 50,
          startBeat: 8,
          durationBeats: 1,
          velocity: 100,
        ),
      ];
      const generated = [
        MidiNoteSnapshot(
          pitch: 60,
          startBeat: 0,
          durationBeats: 4,
          velocity: 100,
        ),
      ];
      final merged = HarmonicAssistantCommit.merge(
        existing: existing,
        generated: generated,
        mode: HarmonicCommitMode.replaceRange,
        playheadBeat: 0,
      );
      expect(merged.length, 2);
      expect(merged.first.pitch, 60);
      expect(merged.last.pitch, 50);
    });
  });

  group('HarmonicNoteOps', () {
    test('groupIndices clusters same startBeat', () {
      const notes = [
        MidiNoteSnapshot(
            pitch: 60, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 64, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 67, startBeat: 4, durationBeats: 4, velocity: 100),
      ];
      expect(HarmonicNoteOps.groupIndices(notes, 0), [0, 1]);
      expect(HarmonicNoteOps.groupIndices(notes, 2), [2]);
    });

    test('insert chord at beat shifts generated notes', () {
      final notes = HarmonicNoteOps.chordNotes(
        scale: PlayScale.major,
        rootPitchClass: 0,
        degree: 1,
        startBeat: 8,
        durationBeats: 4,
        params: HarmonicToolParams()..voiceLeadStrength = 0,
      );
      expect(notes.length, 3);
      expect(notes.every((n) => n.startBeat >= 8), isTrue);
    });

    test('resizeChordBoundary end expands and shrinks neighbor', () {
      const notes = [
        MidiNoteSnapshot(
            pitch: 60, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 64, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 62, startBeat: 4, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 65, startBeat: 4, durationBeats: 4, velocity: 100),
      ];
      final out = HarmonicNoteOps.resizeChordBoundary(
        notes: notes,
        groupIndices: [0, 1],
        fromStart: false,
        proposedBoundary: 6,
        minDuration: 1,
        maxBeat: 16,
      ).$1;
      expect(out[0].durationBeats, 6);
      expect(out[1].durationBeats, 6);
      expect(out[2].startBeat, 6);
      expect(out[2].durationBeats, 2);
      expect(out[3].startBeat, 6);
      expect(out[3].durationBeats, 2);
    });

    test('resizeChordBoundary start fills into previous chord', () {
      const notes = [
        MidiNoteSnapshot(
            pitch: 60, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 62, startBeat: 4, durationBeats: 4, velocity: 100),
      ];
      final out = HarmonicNoteOps.resizeChordBoundary(
        notes: notes,
        groupIndices: [1],
        fromStart: true,
        proposedBoundary: 2,
        minDuration: 1,
        maxBeat: 16,
      ).$1;
      expect(out[0].durationBeats, 2);
      expect(out[1].startBeat, 2);
      expect(out[1].durationBeats, 6);
    });

    test('resizeChordBoundary respects minDuration on both sides', () {
      const notes = [
        MidiNoteSnapshot(
            pitch: 60, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 62, startBeat: 4, durationBeats: 4, velocity: 100),
      ];
      final out = HarmonicNoteOps.resizeChordBoundary(
        notes: notes,
        groupIndices: [0],
        fromStart: false,
        proposedBoundary: 7.5,
        minDuration: 1,
        maxBeat: 16,
      ).$1;
      expect(out[0].durationBeats, 7);
      expect(out[1].startBeat, 7);
      expect(out[1].durationBeats, 1);
    });

    test('chordNotes block fills full requested duration', () {
      final notes = HarmonicNoteOps.chordNotes(
        scale: PlayScale.major,
        rootPitchClass: 0,
        degree: 1,
        startBeat: 0,
        durationBeats: 4,
        params: HarmonicToolParams()..voiceLeadStrength = 0,
      );
      expect(notes, isNotEmpty);
      for (final n in notes) {
        expect(n.durationBeats, 4);
      }
    });

    test('applyRhythm long-long-short cells hit all voices together', () {
      const notes = [
        MidiNoteSnapshot(
            pitch: 60, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 64, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 67, startBeat: 0, durationBeats: 4, velocity: 100),
      ];
      const slots = [ChordSlot(startBeat: 0, endBeat: 4)];
      final preset = ChordRhythmPreset(
        id: 'test_llsss',
        subgenreId: 'house_prog',
        label: 'test',
        cells: [2, 2, 1, 1, 1],
        gate: 1.0,
      );
      final out = HarmonicNoteOps.applyRhythm(
        notes: notes,
        slots: slots,
        preset: preset,
      );
      // 5 hits × 3 pitches
      expect(out.length, 15);
      final starts = out.map((n) => n.startBeat).toSet().toList()..sort();
      expect(starts.length, 5);
      // Each hit has all 3 pitches
      for (final s in starts) {
        expect(out.where((n) => n.startBeat == s).length, 3);
      }
      final blocked = HarmonicNoteOps.applyRhythm(
        notes: out,
        slots: slots,
        preset: ChordRhythmPreset.sustained,
      );
      expect(blocked.length, 3);
      expect(blocked.every((n) => n.durationBeats == 4), isTrue);
    });

    test('groupIndices uses slots across arp starts', () {
      const notes = [
        MidiNoteSnapshot(
            pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
        MidiNoteSnapshot(
            pitch: 64, startBeat: 1, durationBeats: 1, velocity: 100),
        MidiNoteSnapshot(
            pitch: 67, startBeat: 2, durationBeats: 1, velocity: 100),
      ];
      const slots = [ChordSlot(startBeat: 0, endBeat: 4)];
      expect(
        HarmonicNoteOps.groupIndices(notes, 1, slots: slots),
        [0, 1, 2],
      );
    });

    test('nextEmptyStart is 0 when empty, else after last chord', () {
      expect(HarmonicNoteOps.nextEmptyStart(const []), 0);
      const notes = [
        MidiNoteSnapshot(
            pitch: 60, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 64, startBeat: 0, durationBeats: 4, velocity: 100),
        MidiNoteSnapshot(
            pitch: 62, startBeat: 4, durationBeats: 4, velocity: 100),
      ];
      expect(HarmonicNoteOps.nextEmptyStart(notes), 8);
    });

    test('pop radio subgenre lists classic pop progressions', () {
      final list = ProgressionTemplate.forSubgenre('pop_radio');
      expect(list.map((t) => t.id), contains('pop_1564'));
      expect(list.length, greaterThanOrEqualTo(10));
      expect(
        ProgressionTemplate.forSubgenre('elec_trance').length,
        greaterThanOrEqualTo(10),
      );
    });

    test('each rhythm subgenre has at least 10 patterns', () {
      for (final sub in RhythmSubgenre.presets) {
        expect(
          ChordRhythmPreset.forSubgenre(sub.id).length,
          greaterThanOrEqualTo(10),
          reason: sub.id,
        );
      }
    });

    test('each progression subgenre has at least 10 templates', () {
      for (final sub in RhythmSubgenre.presets) {
        expect(
          ProgressionTemplate.forSubgenre(sub.id).length,
          greaterThanOrEqualTo(10),
          reason: sub.id,
        );
      }
    });
  });
}
