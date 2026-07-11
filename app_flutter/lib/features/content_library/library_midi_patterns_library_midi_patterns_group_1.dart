part of 'library_midi_patterns.dart';

final Map<String, LibraryMidiPattern> _library_midi_patternsGroup1 = {
  'edm-bass-offbeat': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      for (var beat = 0.0; beat < LibraryMidiPatterns._loop16; beat += 1.0)
        LibraryMidiPatterns._n(33, beat + 0.5, 0.42, beat % 4 == 2 ? 108 : 96),
    ],
  ),
  'edm-bass-fourfloor': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      for (var beat = 0.0; beat < LibraryMidiPatterns._loop16; beat += 1.0)
        LibraryMidiPatterns._n(33, beat, 0.92, beat % 4 == 0 ? 115 : 98),
    ],
  ),
  'dnb-bass-roller': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      for (var i = 0; i < 64; i++)
        LibraryMidiPatterns._n(28, i * 0.25, 0.22, i % 4 == 0 ? 118 : 86),
    ],
  ),
  'dnb-bass-jumpup': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      LibraryMidiPatterns._n(33, 0.0, 0.35, 115),
      LibraryMidiPatterns._n(38, 1.75, 0.35, 110),
      LibraryMidiPatterns._n(33, 3.5, 0.35, 108),
      LibraryMidiPatterns._n(36, 4.0, 0.35, 115),
      LibraryMidiPatterns._n(40, 5.75, 0.35, 112),
      LibraryMidiPatterns._n(33, 7.5, 0.35, 108),
      LibraryMidiPatterns._n(38, 8.0, 0.35, 115),
      LibraryMidiPatterns._n(33, 9.75, 0.35, 110),
      LibraryMidiPatterns._n(36, 11.5, 0.35, 108),
      LibraryMidiPatterns._n(40, 12.0, 0.35, 118),
      LibraryMidiPatterns._n(33, 14.0, 0.35, 112),
    ],
  ),
  'edm-dnb-groove': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      for (final entry in [
        (33, 0.0),
        (36, 2.0),
        (33, 4.0),
        (31, 6.0),
        (33, 8.0),
        (36, 10.0),
        (33, 12.0),
        (28, 14.0),
      ])
        LibraryMidiPatterns._n(
            entry.$1, entry.$2, 1.85, entry.$2 % 4 == 0 ? 112 : 94),
    ],
  ),

  // ── Progressive house chord leads (5) ───────────────────────────────────
  'prog-chords-cycle': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      ...LibraryMidiPatterns._chord(57, 60, 64, 0, 0.5, 105),
      ...LibraryMidiPatterns._chord(53, 57, 60, 4, 0.5, 102),
      ...LibraryMidiPatterns._chord(48, 52, 55, 8, 0.5, 100),
      ...LibraryMidiPatterns._chord(55, 59, 62, 12, 0.5, 104),
      ...LibraryMidiPatterns._chord(57, 60, 64, 0.5, 0.25, 88),
      ...LibraryMidiPatterns._chord(53, 57, 60, 4.5, 0.25, 86),
      ...LibraryMidiPatterns._chord(48, 52, 55, 8.5, 0.25, 84),
      ...LibraryMidiPatterns._chord(55, 59, 62, 12.5, 0.25, 88),
    ],
  ),
  'prog-chords-uplift': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      ...LibraryMidiPatterns._chord(57, 60, 64, 0, 0.75, 108),
      ...LibraryMidiPatterns._chord(53, 57, 60, 4, 0.75, 104),
      ...LibraryMidiPatterns._chord(60, 64, 67, 8, 0.75, 110),
      ...LibraryMidiPatterns._chord(55, 59, 62, 12, 0.75, 106),
    ],
  ),
  'prog-chords-sparse': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      ...LibraryMidiPatterns._chord(60, 64, 67, 0, 1.5, 98),
      ...LibraryMidiPatterns._chord(55, 59, 62, 8, 1.5, 96),
    ],
  ),
  'prog-chords-rhythm': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      for (var bar = 0; bar < 4; bar++)
        ...LibraryMidiPatterns._chord(57, 60, 64, bar * 4.0, 0.35, 100),
      for (var bar = 0; bar < 4; bar++)
        ...LibraryMidiPatterns._chord(57, 60, 64, bar * 4.0 + 2.0, 0.35, 92),
    ],
  ),
  'prog-chords-wide': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      ...LibraryMidiPatterns._chord(48, 55, 60, 0, 0.6, 104),
      ...LibraryMidiPatterns._chord(45, 52, 57, 4, 0.6, 102),
      ...LibraryMidiPatterns._chord(43, 50, 55, 8, 0.6, 100),
      ...LibraryMidiPatterns._chord(48, 55, 59, 12, 0.6, 106),
    ],
  ),

  // ── Pad clips (5) ───────────────────────────────────────────────────────
  'pad-am-warm': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      ...LibraryMidiPatterns._chord(45, 48, 52, 0, 4, 78),
      ...LibraryMidiPatterns._chord(41, 45, 48, 4, 4, 76),
      ...LibraryMidiPatterns._chord(48, 52, 55, 8, 4, 80),
      ...LibraryMidiPatterns._chord(43, 47, 50, 12, 4, 77),
    ],
  ),
  'pad-fm7-stack': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      LibraryMidiPatterns._n(41, 0, 8, 74),
      LibraryMidiPatterns._n(45, 0, 8, 72),
      LibraryMidiPatterns._n(48, 0, 8, 70),
      LibraryMidiPatterns._n(52, 0, 8, 68),
      LibraryMidiPatterns._n(43, 8, 8, 76),
      LibraryMidiPatterns._n(47, 8, 8, 74),
      LibraryMidiPatterns._n(50, 8, 8, 72),
      LibraryMidiPatterns._n(53, 8, 8, 70),
    ],
  ),
  'pad-dm-emotional': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      ...LibraryMidiPatterns._chord(50, 53, 57, 0, 8, 75),
      ...LibraryMidiPatterns._chord(48, 52, 55, 8, 8, 73),
    ],
  ),
  'pad-epic-rise': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      ...LibraryMidiPatterns._chord(48, 52, 55, 0, 4, 70),
      ...LibraryMidiPatterns._chord(55, 59, 62, 4, 4, 74),
      ...LibraryMidiPatterns._chord(57, 60, 64, 8, 4, 78),
      ...LibraryMidiPatterns._chord(53, 57, 60, 12, 4, 82),
    ],
  ),
  'pad-ambient-cluster': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      for (final pitch in [45, 48, 52, 55, 57, 60])
        LibraryMidiPatterns._n(pitch, 0, 16, 65 + pitch % 5),
    ],
  ),

  // ── EDM melodies (10) ───────────────────────────────────────────────────
  'edm-melody-anthem': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      LibraryMidiPatterns._n(64, 0, 0.5, 108),
      LibraryMidiPatterns._n(67, 0.5, 0.5, 104),
      LibraryMidiPatterns._n(69, 1, 1, 110),
      LibraryMidiPatterns._n(67, 2.5, 0.5, 102),
      LibraryMidiPatterns._n(64, 3, 1, 108),
      LibraryMidiPatterns._n(62, 4, 0.5, 100),
      LibraryMidiPatterns._n(64, 4.5, 0.5, 102),
      LibraryMidiPatterns._n(67, 5, 1.5, 108),
      LibraryMidiPatterns._n(69, 7, 1, 110),
      LibraryMidiPatterns._n(72, 8, 0.75, 112),
      LibraryMidiPatterns._n(69, 9, 0.5, 106),
      LibraryMidiPatterns._n(67, 9.5, 0.5, 104),
      LibraryMidiPatterns._n(64, 10, 2, 108),
      LibraryMidiPatterns._n(62, 12, 0.5, 100),
      LibraryMidiPatterns._n(64, 12.5, 0.5, 102),
      LibraryMidiPatterns._n(67, 13, 1, 108),
      LibraryMidiPatterns._n(64, 14.5, 1.5, 106),
    ],
  ),
  'edm-melody-hook-a': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      LibraryMidiPatterns._n(69, 0, 0.25, 110),
      LibraryMidiPatterns._n(67, 0.5, 0.25, 104),
      LibraryMidiPatterns._n(64, 1, 0.5, 108),
      LibraryMidiPatterns._n(67, 2, 0.5, 104),
      LibraryMidiPatterns._n(69, 3, 1, 110),
      LibraryMidiPatterns._n(67, 4, 0.25, 102),
      LibraryMidiPatterns._n(64, 4.5, 0.25, 100),
      LibraryMidiPatterns._n(62, 5, 0.5, 98),
      LibraryMidiPatterns._n(64, 6, 0.5, 102),
      LibraryMidiPatterns._n(67, 7, 1, 108),
      LibraryMidiPatterns._n(69, 8, 0.25, 110),
      LibraryMidiPatterns._n(67, 8.5, 0.25, 104),
      LibraryMidiPatterns._n(64, 9, 0.5, 108),
      LibraryMidiPatterns._n(67, 10, 0.5, 104),
      LibraryMidiPatterns._n(72, 11, 1, 112),
      LibraryMidiPatterns._n(69, 12, 0.5, 108),
      LibraryMidiPatterns._n(67, 13, 0.5, 104),
      LibraryMidiPatterns._n(64, 14, 2, 106),
    ],
  ),
  'edm-melody-hook-b': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      LibraryMidiPatterns._n(76, 0, 0.5, 112),
      LibraryMidiPatterns._n(74, 0.5, 0.5, 108),
      LibraryMidiPatterns._n(72, 1, 0.5, 110),
      LibraryMidiPatterns._n(69, 2, 0.5, 106),
      LibraryMidiPatterns._n(67, 3, 1, 104),
      LibraryMidiPatterns._n(69, 4, 0.5, 106),
      LibraryMidiPatterns._n(72, 5, 0.5, 108),
      LibraryMidiPatterns._n(74, 6, 1, 110),
      LibraryMidiPatterns._n(76, 8, 0.5, 112),
      LibraryMidiPatterns._n(74, 9, 0.5, 108),
      LibraryMidiPatterns._n(72, 10, 0.5, 106),
      LibraryMidiPatterns._n(69, 11, 0.5, 104),
      LibraryMidiPatterns._n(67, 12, 1, 102),
      LibraryMidiPatterns._n(69, 13, 0.5, 104),
      LibraryMidiPatterns._n(72, 14, 2, 108),
    ],
  ),
  'edm-melody-arpeggio': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop16,
    notes: [
      for (var i = 0; i < 32; i++)
        LibraryMidiPatterns._n(
            [60, 64, 67, 72][i % 4], i * 0.5, 0.45, 95 + (i % 4) * 3),
    ],
  ),
  'edm-melody-drop': LibraryMidiPattern(
    lengthBeats: LibraryMidiPatterns._loop8,
    notes: [
      LibraryMidiPatterns._n(72, 0, 0.25, 115),
      LibraryMidiPatterns._n(69, 0.5, 0.25, 110),
      LibraryMidiPatterns._n(67, 1, 0.5, 112),
      LibraryMidiPatterns._n(64, 2, 0.5, 108),
      LibraryMidiPatterns._n(67, 3, 0.5, 110),
      LibraryMidiPatterns._n(69, 4, 1, 112),
      LibraryMidiPatterns._n(72, 6, 2, 115),
    ],
  ),
};
