/// Named degree sequence (1–7) for Harmonic Assistant.
library;

part 'progression_presets.dart';

class ProgressionTemplate {
  const ProgressionTemplate({
    required this.id,
    required this.label,
    required this.degrees,
    required this.subgenreId,
  });

  final String id;
  final String label;
  final List<int> degrees;
  final String subgenreId;

  static const pop1564 = pop1564Preset;
  static const canon1563 = canon1563Preset;
  static const blues1451 = blues1451Preset;
  static const jazz2511 = jazz2511Preset;
  static const sad6415 = sad6415Preset;
  static const modal1475 = modal1475Preset;
  static const loop1 = loop1Preset;

  static const List<ProgressionTemplate> presets = progressionPresetList;

  static List<ProgressionTemplate> forSubgenre(String subgenreId) => [
        for (final t in presets)
          if (t.subgenreId == subgenreId) t,
      ];

  static ProgressionTemplate byId(String id) {
    for (final t in presets) {
      if (t.id == id) return t;
    }
    return pop1564;
  }
}
