import '../../bridge/project_snapshot.dart';
import 'harmonic_assistant_spec.dart';

/// Merges generated notes into the clip note list (one undo-friendly result).
class HarmonicAssistantCommit {
  const HarmonicAssistantCommit._();

  static List<MidiNoteSnapshot> merge({
    required List<MidiNoteSnapshot> existing,
    required List<MidiNoteSnapshot> generated,
    required HarmonicCommitMode mode,
    required double playheadBeat,
    int? selectedIndex,
  }) {
    if (generated.isEmpty) return List.of(existing);

    final shifted = [
      for (final n in generated)
        MidiNoteSnapshot(
          pitch: n.pitch,
          startBeat: n.startBeat + playheadBeat,
          durationBeats: n.durationBeats,
          velocity: n.velocity,
        ),
    ];
    final genEnd = shifted
        .map((n) => n.startBeat + n.durationBeats)
        .fold<double>(playheadBeat, (a, b) => a > b ? a : b);

    switch (mode) {
      case HarmonicCommitMode.insertAtPlayhead:
        return [...existing, ...shifted]
          ..sort((a, b) => a.startBeat.compareTo(b.startBeat));

      case HarmonicCommitMode.replaceSelection:
        final keep = <MidiNoteSnapshot>[];
        for (var i = 0; i < existing.length; i++) {
          if (selectedIndex != null && i == selectedIndex) continue;
          keep.add(existing[i]);
        }
        final insertAt = selectedIndex != null &&
                selectedIndex >= 0 &&
                selectedIndex < existing.length
            ? existing[selectedIndex].startBeat
            : playheadBeat;
        final atSelection = [
          for (final n in generated)
            MidiNoteSnapshot(
              pitch: n.pitch,
              startBeat: n.startBeat + insertAt,
              durationBeats: n.durationBeats,
              velocity: n.velocity,
            ),
        ];
        return [...keep, ...atSelection]
          ..sort((a, b) => a.startBeat.compareTo(b.startBeat));

      case HarmonicCommitMode.replaceRange:
        final keep = existing.where((n) {
          final end = n.startBeat + n.durationBeats;
          return end <= playheadBeat + 1e-9 || n.startBeat >= genEnd - 1e-9;
        });
        return [...keep, ...shifted]
          ..sort((a, b) => a.startBeat.compareTo(b.startBeat));
    }
  }

  static double requiredClipLength({
    required double currentLength,
    required List<MidiNoteSnapshot> notes,
  }) {
    if (notes.isEmpty) return currentLength;
    final end = notes
        .map((n) => n.startBeat + n.durationBeats)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return end > currentLength ? end : currentLength;
  }
}
