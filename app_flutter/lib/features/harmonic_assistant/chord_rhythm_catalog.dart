/// Chord-stab rhythm catalog: genre → subgenre → cell patterns.
///
/// Cells: positive weight = all chord tones hit together for that share of the
/// slot; negative weight = rest for |weight| share. Example long-long-short×3:
/// `[2, 2, 1, 1, 1]`. Offbeat 8ths: `[-1, 1, -1, 1, -1, 1, -1, 1]`.
library;

part 'chord_rhythm_presets.dart';

enum RhythmGenre {
  electronic,
  house,
  hipHop,
  trap,
  pop,
  rnb,
  rock,
  reggae,
  latin,
}

extension RhythmGenreLabel on RhythmGenre {
  String get label => switch (this) {
        RhythmGenre.electronic => 'Electronic',
        RhythmGenre.house => 'House',
        RhythmGenre.hipHop => 'Hip hop',
        RhythmGenre.trap => 'Trap',
        RhythmGenre.pop => 'Pop',
        RhythmGenre.rnb => 'R&B',
        RhythmGenre.rock => 'Rock',
        RhythmGenre.reggae => 'Reggae',
        RhythmGenre.latin => 'Latin',
      };
}

class RhythmSubgenre {
  const RhythmSubgenre({
    required this.id,
    required this.genre,
    required this.label,
  });

  final String id;
  final RhythmGenre genre;
  final String label;

  static const presets = <RhythmSubgenre>[
    RhythmSubgenre(id: 'elec_edm', genre: RhythmGenre.electronic, label: 'EDM'),
    RhythmSubgenre(
        id: 'elec_trance', genre: RhythmGenre.electronic, label: 'Trance'),
    RhythmSubgenre(
        id: 'elec_techno', genre: RhythmGenre.electronic, label: 'Techno'),
    RhythmSubgenre(id: 'elec_dnb', genre: RhythmGenre.electronic, label: 'DnB'),
    RhythmSubgenre(
        id: 'house_classic', genre: RhythmGenre.house, label: 'Classic'),
    RhythmSubgenre(id: 'house_deep', genre: RhythmGenre.house, label: 'Deep'),
    RhythmSubgenre(id: 'house_tech', genre: RhythmGenre.house, label: 'Tech'),
    RhythmSubgenre(
        id: 'house_prog', genre: RhythmGenre.house, label: 'Progressive'),
    RhythmSubgenre(
        id: 'hh_boombap', genre: RhythmGenre.hipHop, label: 'Boom bap'),
    RhythmSubgenre(
        id: 'hh_modern', genre: RhythmGenre.hipHop, label: 'Modern'),
    RhythmSubgenre(id: 'trap_main', genre: RhythmGenre.trap, label: 'Main'),
    RhythmSubgenre(
        id: 'trap_halftime', genre: RhythmGenre.trap, label: 'Half-time'),
    RhythmSubgenre(id: 'pop_radio', genre: RhythmGenre.pop, label: 'Radio'),
    RhythmSubgenre(id: 'pop_anthem', genre: RhythmGenre.pop, label: 'Anthem'),
    RhythmSubgenre(
        id: 'rnb_quiet', genre: RhythmGenre.rnb, label: 'Quiet storm'),
    RhythmSubgenre(id: 'rnb_alt', genre: RhythmGenre.rnb, label: 'Alt / neo'),
    RhythmSubgenre(
        id: 'rock_straight', genre: RhythmGenre.rock, label: 'Straight'),
    RhythmSubgenre(id: 'rock_drive', genre: RhythmGenre.rock, label: 'Drive'),
    RhythmSubgenre(id: 'reg_skank', genre: RhythmGenre.reggae, label: 'Skank'),
    RhythmSubgenre(
        id: 'reg_dancehall', genre: RhythmGenre.reggae, label: 'Dancehall'),
    RhythmSubgenre(
        id: 'lat_tresillo', genre: RhythmGenre.latin, label: 'Tresillo'),
    RhythmSubgenre(id: 'lat_clave', genre: RhythmGenre.latin, label: 'Clave'),
  ];

  static List<RhythmSubgenre> forGenre(RhythmGenre genre) => [
        for (final s in presets)
          if (s.genre == genre) s,
      ];

  static RhythmSubgenre byId(String id) => presets.firstWhere(
        (s) => s.id == id,
        orElse: () => presets.first,
      );
}

/// One named chord rhythm (all voices move together).
class ChordRhythmPreset {
  const ChordRhythmPreset({
    required this.id,
    required this.subgenreId,
    required this.label,
    required this.cells,
    this.gate = 0.92,
  });

  final String id;
  final String subgenreId;
  final String label;

  /// Positive = hit, negative = rest (|w|).
  final List<double> cells;
  final double gate;

  static const sustained = ChordRhythmPreset(
    id: 'sustained',
    subgenreId: 'pop_radio',
    label: 'Sustained',
    cells: [1],
    gate: 1.0,
  );

  static const presets = chordRhythmPresetList;

  static List<ChordRhythmPreset> forSubgenre(String subgenreId) {
    final list = [
      for (final p in presets)
        if (p.subgenreId == subgenreId) p,
    ];
    if (list.isEmpty) return const [sustained];
    return list;
  }

  static ChordRhythmPreset byId(String id) => presets.firstWhere(
        (p) => p.id == id,
        orElse: () => sustained,
      );
}
