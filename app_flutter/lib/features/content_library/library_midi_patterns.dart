import '../../bridge/clip_snapshots.dart';

/// Bundled factory MIDI loop definitions referenced by the content library manifest.
class LibraryMidiPattern {
  const LibraryMidiPattern({
    required this.lengthBeats,
    required this.notes,
  });

  final double lengthBeats;
  final List<MidiNoteSnapshot> notes;

  MidiClipSnapshot toClip(String id) => MidiClipSnapshot(
        id: id,
        startBeat: 0,
        lengthBeats: lengthBeats,
        notes: notes,
      );
}

abstract final class LibraryMidiPatterns {
  static const _loop16 = 16.0;
  static const _loop8 = 8.0;

  static MidiNoteSnapshot _n(
    int pitch,
    double start,
    double dur, [
    double vel = 100,
  ]) =>
      MidiNoteSnapshot(
        pitch: pitch,
        startBeat: start,
        durationBeats: dur,
        velocity: vel,
      );

  static List<MidiNoteSnapshot> _chord(
    int root,
    int third,
    int fifth,
    double start,
    double dur, [
    double vel = 100,
  ]) =>
      [
        _n(root, start, dur, vel),
        _n(third, start, dur, vel),
        _n(fifth, start, dur, vel),
      ];

  static final Map<String, LibraryMidiPattern> patterns = {
    // ── EDM + DnB basslines (5) ───────────────────────────────────────────
    'edm-bass-offbeat': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        for (var beat = 0.0; beat < _loop16; beat += 1.0)
          _n(33, beat + 0.5, 0.42, beat % 4 == 2 ? 108 : 96),
      ],
    ),
    'edm-bass-fourfloor': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        for (var beat = 0.0; beat < _loop16; beat += 1.0)
          _n(33, beat, 0.92, beat % 4 == 0 ? 115 : 98),
      ],
    ),
    'dnb-bass-roller': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        for (var i = 0; i < 64; i++)
          _n(28, i * 0.25, 0.22, i % 4 == 0 ? 118 : 86),
      ],
    ),
    'dnb-bass-jumpup': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        _n(33, 0.0, 0.35, 115),
        _n(38, 1.75, 0.35, 110),
        _n(33, 3.5, 0.35, 108),
        _n(36, 4.0, 0.35, 115),
        _n(40, 5.75, 0.35, 112),
        _n(33, 7.5, 0.35, 108),
        _n(38, 8.0, 0.35, 115),
        _n(33, 9.75, 0.35, 110),
        _n(36, 11.5, 0.35, 108),
        _n(40, 12.0, 0.35, 118),
        _n(33, 14.0, 0.35, 112),
      ],
    ),
    'edm-dnb-groove': LibraryMidiPattern(
      lengthBeats: _loop16,
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
          _n(entry.$1, entry.$2, 1.85, entry.$2 % 4 == 0 ? 112 : 94),
      ],
    ),

    // ── Progressive house chord leads (5) ───────────────────────────────────
    'prog-chords-cycle': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        ..._chord(57, 60, 64, 0, 0.5, 105),
        ..._chord(53, 57, 60, 4, 0.5, 102),
        ..._chord(48, 52, 55, 8, 0.5, 100),
        ..._chord(55, 59, 62, 12, 0.5, 104),
        ..._chord(57, 60, 64, 0.5, 0.25, 88),
        ..._chord(53, 57, 60, 4.5, 0.25, 86),
        ..._chord(48, 52, 55, 8.5, 0.25, 84),
        ..._chord(55, 59, 62, 12.5, 0.25, 88),
      ],
    ),
    'prog-chords-uplift': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        ..._chord(57, 60, 64, 0, 0.75, 108),
        ..._chord(53, 57, 60, 4, 0.75, 104),
        ..._chord(60, 64, 67, 8, 0.75, 110),
        ..._chord(55, 59, 62, 12, 0.75, 106),
      ],
    ),
    'prog-chords-sparse': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        ..._chord(60, 64, 67, 0, 1.5, 98),
        ..._chord(55, 59, 62, 8, 1.5, 96),
      ],
    ),
    'prog-chords-rhythm': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        for (var bar = 0; bar < 4; bar++)
          ..._chord(57, 60, 64, bar * 4.0, 0.35, 100),
        for (var bar = 0; bar < 4; bar++)
          ..._chord(57, 60, 64, bar * 4.0 + 2.0, 0.35, 92),
      ],
    ),
    'prog-chords-wide': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        ..._chord(48, 55, 60, 0, 0.6, 104),
        ..._chord(45, 52, 57, 4, 0.6, 102),
        ..._chord(43, 50, 55, 8, 0.6, 100),
        ..._chord(48, 55, 59, 12, 0.6, 106),
      ],
    ),

    // ── Pad clips (5) ───────────────────────────────────────────────────────
    'pad-am-warm': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        ..._chord(45, 48, 52, 0, 4, 78),
        ..._chord(41, 45, 48, 4, 4, 76),
        ..._chord(48, 52, 55, 8, 4, 80),
        ..._chord(43, 47, 50, 12, 4, 77),
      ],
    ),
    'pad-fm7-stack': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        _n(41, 0, 8, 74),
        _n(45, 0, 8, 72),
        _n(48, 0, 8, 70),
        _n(52, 0, 8, 68),
        _n(43, 8, 8, 76),
        _n(47, 8, 8, 74),
        _n(50, 8, 8, 72),
        _n(53, 8, 8, 70),
      ],
    ),
    'pad-dm-emotional': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        ..._chord(50, 53, 57, 0, 8, 75),
        ..._chord(48, 52, 55, 8, 8, 73),
      ],
    ),
    'pad-epic-rise': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        ..._chord(48, 52, 55, 0, 4, 70),
        ..._chord(55, 59, 62, 4, 4, 74),
        ..._chord(57, 60, 64, 8, 4, 78),
        ..._chord(53, 57, 60, 12, 4, 82),
      ],
    ),
    'pad-ambient-cluster': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        for (final pitch in [45, 48, 52, 55, 57, 60])
          _n(pitch, 0, 16, 65 + pitch % 5),
      ],
    ),

    // ── EDM melodies (10) ───────────────────────────────────────────────────
    'edm-melody-anthem': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        _n(64, 0, 0.5, 108),
        _n(67, 0.5, 0.5, 104),
        _n(69, 1, 1, 110),
        _n(67, 2.5, 0.5, 102),
        _n(64, 3, 1, 108),
        _n(62, 4, 0.5, 100),
        _n(64, 4.5, 0.5, 102),
        _n(67, 5, 1.5, 108),
        _n(69, 7, 1, 110),
        _n(72, 8, 0.75, 112),
        _n(69, 9, 0.5, 106),
        _n(67, 9.5, 0.5, 104),
        _n(64, 10, 2, 108),
        _n(62, 12, 0.5, 100),
        _n(64, 12.5, 0.5, 102),
        _n(67, 13, 1, 108),
        _n(64, 14.5, 1.5, 106),
      ],
    ),
    'edm-melody-hook-a': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        _n(69, 0, 0.25, 110),
        _n(67, 0.5, 0.25, 104),
        _n(64, 1, 0.5, 108),
        _n(67, 2, 0.5, 104),
        _n(69, 3, 1, 110),
        _n(67, 4, 0.25, 102),
        _n(64, 4.5, 0.25, 100),
        _n(62, 5, 0.5, 98),
        _n(64, 6, 0.5, 102),
        _n(67, 7, 1, 108),
        _n(69, 8, 0.25, 110),
        _n(67, 8.5, 0.25, 104),
        _n(64, 9, 0.5, 108),
        _n(67, 10, 0.5, 104),
        _n(72, 11, 1, 112),
        _n(69, 12, 0.5, 108),
        _n(67, 13, 0.5, 104),
        _n(64, 14, 2, 106),
      ],
    ),
    'edm-melody-hook-b': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        _n(76, 0, 0.5, 112),
        _n(74, 0.5, 0.5, 108),
        _n(72, 1, 0.5, 110),
        _n(69, 2, 0.5, 106),
        _n(67, 3, 1, 104),
        _n(69, 4, 0.5, 106),
        _n(72, 5, 0.5, 108),
        _n(74, 6, 1, 110),
        _n(76, 8, 0.5, 112),
        _n(74, 9, 0.5, 108),
        _n(72, 10, 0.5, 106),
        _n(69, 11, 0.5, 104),
        _n(67, 12, 1, 102),
        _n(69, 13, 0.5, 104),
        _n(72, 14, 2, 108),
      ],
    ),
    'edm-melody-arpeggio': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        for (var i = 0; i < 32; i++)
          _n([60, 64, 67, 72][i % 4], i * 0.5, 0.45, 95 + (i % 4) * 3),
      ],
    ),
    'edm-melody-drop': LibraryMidiPattern(
      lengthBeats: _loop8,
      notes: [
        _n(72, 0, 0.25, 115),
        _n(69, 0.5, 0.25, 110),
        _n(67, 1, 0.5, 112),
        _n(64, 2, 0.5, 108),
        _n(67, 3, 0.5, 110),
        _n(69, 4, 1, 112),
        _n(72, 6, 2, 115),
      ],
    ),
    'edm-melody-pluck': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        for (final entry in [
          (76, 0.0),
          (74, 1.0),
          (72, 2.0),
          (69, 3.0),
          (72, 4.0),
          (74, 5.0),
          (76, 6.0),
          (79, 7.0),
          (76, 8.0),
          (74, 9.0),
          (72, 10.0),
          (69, 11.0),
          (67, 12.0),
          (69, 13.0),
          (72, 14.0),
          (74, 15.0),
        ])
          _n(entry.$1, entry.$2, 0.35, 104),
      ],
    ),
    'edm-melody-festival': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        _n(79, 0, 0.5, 114),
        _n(76, 0.5, 0.5, 110),
        _n(79, 1, 0.5, 114),
        _n(81, 2, 1, 116),
        _n(79, 4, 0.5, 112),
        _n(76, 5, 0.5, 108),
        _n(74, 6, 1, 106),
        _n(76, 8, 0.5, 110),
        _n(79, 9, 0.5, 112),
        _n(81, 10, 1.5, 116),
        _n(79, 12, 0.5, 112),
        _n(76, 13, 0.5, 108),
        _n(74, 14, 2, 106),
      ],
    ),
    'edm-melody-night': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        _n(62, 0, 0.75, 98),
        _n(64, 1, 0.5, 100),
        _n(67, 2, 0.5, 102),
        _n(64, 3, 0.75, 100),
        _n(62, 4, 1, 98),
        _n(59, 6, 0.5, 94),
        _n(62, 7, 1, 98),
        _n(64, 8, 0.75, 100),
        _n(67, 9, 0.5, 102),
        _n(69, 10, 1, 104),
        _n(67, 12, 0.5, 102),
        _n(64, 13, 0.5, 100),
        _n(62, 14, 2, 98),
      ],
    ),
    'edm-melody-rise': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        _n(60, 0, 0.5, 96),
        _n(62, 1, 0.5, 98),
        _n(64, 2, 0.5, 100),
        _n(67, 3, 0.5, 102),
        _n(69, 4, 0.5, 104),
        _n(72, 5, 0.5, 106),
        _n(74, 6, 0.5, 108),
        _n(76, 7, 0.5, 110),
        _n(79, 8, 1, 112),
        _n(81, 10, 1, 114),
        _n(84, 12, 2, 116),
        _n(81, 14, 2, 114),
      ],
    ),
    'edm-melody-chant': LibraryMidiPattern(
      lengthBeats: _loop16,
      notes: [
        for (var rep = 0; rep < 4; rep++) ...[
          _n(67, rep * 4.0, 0.5, 108),
          _n(67, rep * 4.0 + 0.75, 0.25, 100),
          _n(64, rep * 4.0 + 1.5, 0.5, 104),
          _n(67, rep * 4.0 + 2.5, 0.75, 106),
        ],
      ],
    ),
  };
}
