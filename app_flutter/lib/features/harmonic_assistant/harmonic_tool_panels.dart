import 'package:flutter/material.dart';

import '../music_theory/progression_templates.dart';
import '../piano_roll/piano_roll_theme.dart';
import '../play/play_scale.dart';
import 'chord_rhythm_catalog.dart';
import 'harmonic_degree_pads.dart';
import 'harmonic_note_ops.dart';
import 'harmonic_variation_bar.dart';

/// Tool panel under the context strip for Harmonic mode.
class HarmonicToolPanel extends StatelessWidget {
  const HarmonicToolPanel({
    super.key,
    required this.scale,
    required this.rootPitchClass,
    required this.armedDegree,
    required this.params,
    required this.onDegreeTap,
    required this.onParamsChanged,
  });

  final PlayScale scale;
  final int rootPitchClass;
  final int armedDegree;
  final HarmonicToolParams params;
  final ValueChanged<int> onDegreeTap;
  final ValueChanged<HarmonicToolParams> onParamsChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HarmonicDegreePads(
              scale: scale,
              rootPitchClass: rootPitchClass,
              sevenths: params.sevenths,
              armedDegree: armedDegree,
              onDegreeTap: onDegreeTap,
            ),
            const SizedBox(height: 6),
            HarmonicVariationBar(
              params: params,
              onChanged: onParamsChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tool panel for Progression mode: genre → subgenre → progression.
class ProgressionToolPanel extends StatelessWidget {
  const ProgressionToolPanel({
    super.key,
    required this.genre,
    required this.subgenreId,
    required this.templateId,
    required this.onGenreChanged,
    required this.onSubgenreChanged,
    required this.onTemplateChanged,
  });

  final RhythmGenre genre;
  final String subgenreId;
  final String templateId;
  final ValueChanged<RhythmGenre> onGenreChanged;
  final ValueChanged<String> onSubgenreChanged;
  final ValueChanged<String> onTemplateChanged;

  @override
  Widget build(BuildContext context) {
    final subgenres = RhythmSubgenre.forGenre(genre);
    final subId = subgenres.any((s) => s.id == subgenreId)
        ? subgenreId
        : subgenres.first.id;
    final templates = ProgressionTemplate.forSubgenre(subId);
    final selected = templates.any((t) => t.id == templateId)
        ? templateId
        : (templates.isEmpty ? null : templates.first.id);

    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: _DarkDropdown<RhythmGenre>(
                value: genre,
                items: RhythmGenre.values,
                labelOf: (g) => g.label,
                onChanged: onGenreChanged,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _DarkDropdown<String>(
                value: subId,
                items: [for (final s in subgenres) s.id],
                labelOf: (id) => RhythmSubgenre.byId(id).label,
                onChanged: onSubgenreChanged,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _DarkDropdown<String>(
                value: selected,
                items: [for (final t in templates) t.id],
                labelOf: (id) => ProgressionTemplate.byId(id).label,
                onChanged: onTemplateChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tool panel for Rhythm mode: genre → subgenre → chord rhythm.
class RhythmToolPanel extends StatelessWidget {
  const RhythmToolPanel({
    super.key,
    required this.genre,
    required this.subgenreId,
    required this.rhythmId,
    required this.onGenreChanged,
    required this.onSubgenreChanged,
    required this.onRhythmChanged,
  });

  final RhythmGenre genre;
  final String subgenreId;
  final String rhythmId;
  final ValueChanged<RhythmGenre> onGenreChanged;
  final ValueChanged<String> onSubgenreChanged;
  final ValueChanged<String> onRhythmChanged;

  @override
  Widget build(BuildContext context) {
    final subgenres = RhythmSubgenre.forGenre(genre);
    final subId = subgenres.any((s) => s.id == subgenreId)
        ? subgenreId
        : subgenres.first.id;
    final rhythms = ChordRhythmPreset.forSubgenre(subId);
    final selected = rhythms.any((r) => r.id == rhythmId)
        ? rhythmId
        : rhythms.first.id;

    return ColoredBox(
      color: PianoRollTheme.dockBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: _DarkDropdown<RhythmGenre>(
                value: genre,
                items: RhythmGenre.values,
                labelOf: (g) => g.label,
                onChanged: onGenreChanged,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _DarkDropdown<String>(
                value: subId,
                items: [for (final s in subgenres) s.id],
                labelOf: (id) => RhythmSubgenre.byId(id).label,
                onChanged: onSubgenreChanged,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _DarkDropdown<String>(
                value: selected,
                items: [for (final r in rhythms) r.id],
                labelOf: (id) => ChordRhythmPreset.byId(id).label,
                onChanged: onRhythmChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkDropdown<T> extends StatelessWidget {
  const _DarkDropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  // Match PianoRollGridSheet View dropdown chrome.
  static const _fieldFill = Color(0xFF22222C);
  static const _menuFill = Color(0xFF22222C);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isDense: true,
      isExpanded: true,
      dropdownColor: _menuFill,
      iconEnabledColor: PianoRollTheme.labelMuted,
      decoration: const InputDecoration(
        filled: true,
        fillColor: _fieldFill,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderSide: BorderSide.none),
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Text(labelOf(item)),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
