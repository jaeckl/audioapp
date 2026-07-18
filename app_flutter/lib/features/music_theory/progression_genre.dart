import '../harmonic_assistant/chord_rhythm_catalog.dart';
import 'progression_templates.dart';

export '../harmonic_assistant/chord_rhythm_catalog.dart'
    show RhythmGenre, RhythmGenreLabel, RhythmSubgenre;

/// Progression picker uses the same genre / subgenre taxonomy as Rhythm.
extension ProgressionTemplateTaxonomy on ProgressionTemplate {
  RhythmGenre get genre => RhythmSubgenre.byId(subgenreId).genre;

  static List<ProgressionTemplate> forGenre(RhythmGenre genre) => [
        for (final t in ProgressionTemplate.presets)
          if (t.genre == genre) t,
      ];

  static List<ProgressionTemplate> forSubgenre(String subgenreId) =>
      ProgressionTemplate.forSubgenre(subgenreId);
}
