import '../../bridge/project_snapshot.dart';
import '../music_theory/diatonic_harmony.dart';
import '../music_theory/progression_templates.dart';
import '../play/play_scale.dart';
import 'chord_rhythm_catalog.dart';
import 'harmonic_assistant_generator.dart';
import 'harmonic_assistant_rhythm.dart';
import 'harmonic_assistant_spec.dart';
import 'harmonic_draft.dart';

/// Live chord/progression ops against clip note lists.
class HarmonicNoteOps {
  const HarmonicNoteOps._();

  static const _beatEps = 0.001;

  /// Note indices in the same chord slot / start-beat cluster as [index].
  static List<int> groupIndices(
    List<MidiNoteSnapshot> notes,
    int index, {
    List<ChordSlot>? slots,
  }) {
    if (index < 0 || index >= notes.length) return const [];
    final regions = chordRegions(notes, slots: slots);
    for (final r in regions) {
      if (r.noteIndices.contains(index)) return r.noteIndices;
    }
    return [index];
  }

  static double groupDuration(List<MidiNoteSnapshot> notes, List<int> indices) {
    if (indices.isEmpty) return 4;
    var minStart = double.infinity;
    var maxEnd = 0.0;
    for (final i in indices) {
      final n = notes[i];
      if (n.startBeat < minStart) minStart = n.startBeat;
      final end = n.startBeat + n.durationBeats;
      if (end > maxEnd) maxEnd = end;
    }
    if (!minStart.isFinite) return 4;
    final span = maxEnd - minStart;
    return span < 0.25 ? 4.0 : span;
  }

  static bool noteInSlot(MidiNoteSnapshot note, ChordSlot slot) =>
      note.startBeat >= slot.startBeat - _beatEps &&
      note.startBeat < slot.endBeat - _beatEps;

  /// Derive slots from block-style clustering (same start beat).
  static List<ChordSlot> slotsFromNotes(List<MidiNoteSnapshot> notes) => [
        for (final r in chordRegions(notes))
          ChordSlot(startBeat: r.startBeat, endBeat: r.endBeat),
      ];

  /// Drop slots with no notes; keep original span (rhythm-stable).
  static List<ChordSlot> pruneSlots(
    List<ChordSlot> slots,
    List<MidiNoteSnapshot> notes,
  ) =>
      [
        for (final s in slots)
          if (notes.any((n) => noteInSlot(n, s))) s,
      ];

  static List<MidiNoteSnapshot> chordNotes({
    required PlayScale scale,
    required int rootPitchClass,
    required int degree,
    required double startBeat,
    required double durationBeats,
    required HarmonicToolParams params,
  }) {
    final draft = HarmonicDraft(
      scale: scale,
      rootPitchClass: rootPitchClass,
      blocks: [
        HarmonicChordBlock(degree: degree, durationBeats: durationBeats),
      ],
      sevenths: params.sevenths,
      octaveCenter: params.octaveCenter,
      width: params.width,
      voiceLeadStrength: params.voiceLeadStrength,
      rhythm: params.rhythm,
      gate: params.gate,
      strumBeats: params.strumBeats,
      arpSubdivisions: params.arpSubdivisions,
      velocity: params.velocity,
    );
    final generated = HarmonicAssistantGenerator.generateDraft(draft);
    return [
      for (final n in generated)
        MidiNoteSnapshot(
          pitch: n.pitch,
          startBeat: n.startBeat + startBeat,
          durationBeats: n.durationBeats,
          velocity: n.velocity,
        ),
    ];
  }

  static List<MidiNoteSnapshot> progressionNotes({
    required PlayScale scale,
    required int rootPitchClass,
    required ProgressionTemplate template,
    required double startBeat,
    required HarmonicToolParams params,
    double beatsPerChord = 4,
  }) {
    final draft = HarmonicDraft(
      scale: scale,
      rootPitchClass: rootPitchClass,
      blocks: [
        for (final d in template.degrees)
          HarmonicChordBlock(degree: d, durationBeats: beatsPerChord),
      ],
      sevenths: params.sevenths,
      octaveCenter: params.octaveCenter,
      width: params.width,
      voiceLeadStrength: params.voiceLeadStrength,
      rhythm: params.rhythm,
      gate: params.gate,
      strumBeats: params.strumBeats,
      arpSubdivisions: params.arpSubdivisions,
      velocity: params.velocity,
    );
    final generated = HarmonicAssistantGenerator.generateDraft(draft);
    return [
      for (final n in generated)
        MidiNoteSnapshot(
          pitch: n.pitch,
          startBeat: n.startBeat + startBeat,
          durationBeats: n.durationBeats,
          velocity: n.velocity,
        ),
    ];
  }

  static List<MidiNoteSnapshot> insertNotes({
    required List<MidiNoteSnapshot> existing,
    required List<MidiNoteSnapshot> added,
  }) {
    return [...existing, ...added]
      ..sort((a, b) => a.startBeat.compareTo(b.startBeat));
  }

  static List<MidiNoteSnapshot> replaceGroup({
    required List<MidiNoteSnapshot> existing,
    required List<int> groupIndices,
    required List<MidiNoteSnapshot> replacement,
  }) {
    final drop = groupIndices.toSet();
    final kept = [
      for (var i = 0; i < existing.length; i++)
        if (!drop.contains(i)) existing[i],
    ];
    return insertNotes(existing: kept, added: replacement);
  }

  static String? degreeLabel({
    required PlayScale scale,
    required int rootPitchClass,
    required int degree,
    bool sevenths = false,
  }) {
    return DiatonicHarmony.chordForDegree(
      scale: scale,
      rootPitchClass: rootPitchClass,
      degree: degree,
      sevenths: sevenths,
    )?.label;
  }

  /// Chord clusters from [slots] when provided; else same-startBeat groups.
  static List<ChordRegion> chordRegions(
    List<MidiNoteSnapshot> notes, {
    List<ChordSlot>? slots,
  }) {
    if (notes.isEmpty) return const [];
    if (slots != null && slots.isNotEmpty) {
      final sorted = List<ChordSlot>.of(slots)
        ..sort((a, b) => a.startBeat.compareTo(b.startBeat));
      return [
        for (final s in sorted)
          ChordRegion(
            startBeat: s.startBeat,
            endBeat: s.endBeat,
            noteIndices: [
              for (var i = 0; i < notes.length; i++)
                if (noteInSlot(notes[i], s)) i,
            ],
          ),
      ];
    }
    final byStart = <double, List<int>>{};
    for (var i = 0; i < notes.length; i++) {
      final key = notes[i].startBeat;
      var matched = false;
      for (final existing in byStart.keys) {
        if ((existing - key).abs() < _beatEps) {
          byStart[existing]!.add(i);
          matched = true;
          break;
        }
      }
      if (!matched) byStart[key] = [i];
    }
    final starts = byStart.keys.toList()..sort();
    return [
      for (final start in starts)
        ChordRegion(
          startBeat: start,
          endBeat: start + groupDuration(notes, byStart[start]!),
          noteIndices: byStart[start]!,
        ),
    ];
  }

  static double nextEmptyStart(
    List<MidiNoteSnapshot> notes, {
    List<ChordSlot>? slots,
  }) {
    final regions = chordRegions(notes, slots: slots);
    if (regions.isEmpty) return 0;
    var end = 0.0;
    for (final r in regions) {
      if (r.endBeat > end) end = r.endBeat;
    }
    return end;
  }

  /// Re-articulate every chord slot with [preset] (all voices together).
  /// Slot spans stay fixed so switching patterns never subdivides further.
  static List<MidiNoteSnapshot> applyRhythm({
    required List<MidiNoteSnapshot> notes,
    required List<ChordSlot> slots,
    required ChordRhythmPreset preset,
    double? velocityScale,
  }) {
    if (slots.isEmpty) return List.of(notes);
    final regions = chordRegions(notes, slots: slots);
    final out = <MidiNoteSnapshot>[];
    for (final r in regions) {
      if (r.noteIndices.isEmpty || r.durationBeats <= 0) continue;
      final pitches = <int>{
        for (final i in r.noteIndices) notes[i].pitch,
      }.toList()
        ..sort();
      var velocity = 0.0;
      for (final i in r.noteIndices) {
        velocity += notes[i].velocity;
      }
      velocity /= r.noteIndices.length;
      if (velocityScale != null) velocity *= velocityScale;
      out.addAll(
        HarmonicAssistantRhythm.notesForPreset(
          pitches: pitches,
          startBeat: r.startBeat,
          slotBeats: r.durationBeats,
          preset: preset,
          velocity: velocity,
        ),
      );
    }
    out.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    return out;
  }

  /// Resize a chord region from left or right; neighbor absorbs/fills so
  /// chord regions stay abutting without overlap.
  static (List<MidiNoteSnapshot>, List<ChordSlot>) resizeChordBoundary({
    required List<MidiNoteSnapshot> notes,
    required List<int> groupIndices,
    required bool fromStart,
    required double proposedBoundary,
    required double minDuration,
    required double maxBeat,
    List<ChordSlot>? slots,
  }) {
    if (groupIndices.isEmpty) {
      return (List.of(notes), slots ?? slotsFromNotes(notes));
    }
    final workingSlots = slots != null && slots.isNotEmpty
        ? (List<ChordSlot>.of(slots)
          ..sort((a, b) => a.startBeat.compareTo(b.startBeat)))
        : slotsFromNotes(notes);
    final regions = chordRegions(notes, slots: workingSlots);
    final groupSet = groupIndices.toSet();
    final activeIdx = regions.indexWhere(
      (r) => r.noteIndices.any(groupSet.contains),
    );
    if (activeIdx < 0) return (List.of(notes), workingSlots);

    final active = regions[activeIdx];
    final out = List<MidiNoteSnapshot>.of(notes);

    if (fromStart) {
      final prev = activeIdx > 0 ? regions[activeIdx - 1] : null;
      var newStart = proposedBoundary;
      final minStart = prev != null ? prev.startBeat + minDuration : 0.0;
      final maxStart = active.endBeat - minDuration;
      if (newStart < minStart) newStart = minStart;
      if (newStart > maxStart) newStart = maxStart;
      workingSlots[activeIdx] =
          ChordSlot(startBeat: newStart, endBeat: active.endBeat);
      if (prev != null) {
        workingSlots[activeIdx - 1] =
            ChordSlot(startBeat: prev.startBeat, endBeat: newStart);
      }
      _writeRegion(out, active.noteIndices, newStart, active.endBeat);
      if (prev != null) {
        _writeRegion(out, prev.noteIndices, prev.startBeat, newStart);
      }
    } else {
      final next =
          activeIdx + 1 < regions.length ? regions[activeIdx + 1] : null;
      var newEnd = proposedBoundary;
      final minEnd = active.startBeat + minDuration;
      final maxEnd = next != null ? next.endBeat - minDuration : maxBeat;
      if (newEnd < minEnd) newEnd = minEnd;
      if (newEnd > maxEnd) newEnd = maxEnd;
      workingSlots[activeIdx] =
          ChordSlot(startBeat: active.startBeat, endBeat: newEnd);
      if (next != null) {
        workingSlots[activeIdx + 1] =
            ChordSlot(startBeat: newEnd, endBeat: next.endBeat);
      }
      _writeRegion(out, active.noteIndices, active.startBeat, newEnd);
      if (next != null) {
        _writeRegion(out, next.noteIndices, newEnd, next.endBeat);
      }
    }
    return (out, workingSlots);
  }

  static void _writeRegion(
    List<MidiNoteSnapshot> notes,
    List<int> indices,
    double start,
    double end,
  ) {
    final dur = (end - start).clamp(0.01, 1e9);
    for (final i in indices) {
      notes[i] = MidiNoteSnapshot(
        pitch: notes[i].pitch,
        startBeat: start,
        durationBeats: dur,
        velocity: notes[i].velocity,
      );
    }
  }
}

/// Stable chord time span — survives rhythm note splits.
class ChordSlot {
  const ChordSlot({required this.startBeat, required this.endBeat});

  final double startBeat;
  final double endBeat;

  double get durationBeats => endBeat - startBeat;
}

/// One chord cluster on the timeline.
class ChordRegion {
  const ChordRegion({
    required this.startBeat,
    required this.endBeat,
    required this.noteIndices,
  });

  final double startBeat;
  final double endBeat;
  final List<int> noteIndices;

  double get durationBeats => endBeat - startBeat;
}

/// Shared voicing/rhythm knobs for Harmonic + Progression tools.
class HarmonicToolParams {
  HarmonicToolParams({
    this.sevenths = false,
    this.octaveCenter = 60,
    this.width = HarmonicVoicingWidth.close,
    this.voiceLeadStrength = 0.7,
    this.rhythm = HarmonicRhythmPattern.block,
    this.gate = 1.0,
    this.strumBeats = 0.05,
    this.arpSubdivisions = 4,
    this.velocity = 100,
    this.beatsPerChord = 4,
  });

  bool sevenths;
  int octaveCenter;
  HarmonicVoicingWidth width;
  double voiceLeadStrength;
  HarmonicRhythmPattern rhythm;
  double gate;
  double strumBeats;
  int arpSubdivisions;
  double velocity;
  double beatsPerChord;

  HarmonicToolParams copy() {
    return HarmonicToolParams(
      sevenths: sevenths,
      octaveCenter: octaveCenter,
      width: width,
      voiceLeadStrength: voiceLeadStrength,
      rhythm: rhythm,
      gate: gate,
      strumBeats: strumBeats,
      arpSubdivisions: arpSubdivisions,
      velocity: velocity,
      beatsPerChord: beatsPerChord,
    );
  }
}
