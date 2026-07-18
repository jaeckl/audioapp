import '../../bridge/project_snapshot.dart';
import '../music_theory/diatonic_harmony.dart';
import 'harmonic_assistant_rhythm.dart';
import 'harmonic_assistant_spec.dart';
import 'harmonic_assistant_voicing.dart';
import 'harmonic_draft.dart';

/// Deterministic progression → MIDI notes pipeline.
class HarmonicAssistantGenerator {
  const HarmonicAssistantGenerator._();

  static List<MidiNoteSnapshot> generate(HarmonicAssistantSpec spec) {
    final draft = HarmonicDraft(
      scale: spec.scale,
      rootPitchClass: spec.rootPitchClass,
      blocks: [
        for (var rep = 0; rep < spec.repeats; rep++)
          for (final degree in spec.degrees)
            HarmonicChordBlock(
              degree: degree,
              durationBeats: spec.beatsPerChord,
              inversion: spec.inversion,
            ),
      ],
      sevenths: spec.sevenths,
      octaveCenter: spec.octaveCenter,
      width: spec.width,
      voiceLeadStrength: spec.voiceLeadStrength,
      rhythm: spec.rhythm,
      gate: spec.gate,
      strumBeats: spec.strumBeats,
      arpSubdivisions: spec.arpSubdivisions,
      velocity: spec.velocity,
    );
    return generateDraft(draft);
  }

  static List<MidiNoteSnapshot> generateDraft(HarmonicDraft draft) {
    if (draft.blocks.isEmpty) return const [];

    final rhythmSpec = HarmonicAssistantSpec(
      scale: draft.scale,
      rootPitchClass: draft.rootPitchClass,
      degrees: const [],
      sevenths: draft.sevenths,
      octaveCenter: draft.octaveCenter,
      width: draft.width,
      voiceLeadStrength: draft.voiceLeadStrength,
      rhythm: draft.rhythm,
      gate: draft.gate,
      strumBeats: draft.strumBeats,
      arpSubdivisions: draft.arpSubdivisions,
      velocity: draft.velocity,
    );

    final out = <MidiNoteSnapshot>[];
    List<int>? previous;
    var beat = 0.0;

    for (final block in draft.blocks) {
      if (block.durationBeats <= 0) continue;
      final chord = DiatonicHarmony.chordForDegree(
        scale: draft.scale,
        rootPitchClass: draft.rootPitchClass,
        degree: block.degree,
        sevenths: draft.sevenths,
      );
      if (chord == null) continue;

      var pitches = HarmonicAssistantVoicing.pitches(
        rootPitchClass: chord.rootPitchClass,
        quality: chord.quality,
        octaveCenter: draft.octaveCenter,
        inversion: block.inversion,
        width: draft.width,
        previousPitches: previous,
        voiceLeadStrength: draft.voiceLeadStrength,
      );
      if (block.pitchOffset != 0) {
        pitches = [
          for (final p in pitches) (p + block.pitchOffset).clamp(0, 127),
        ];
      }
      out.addAll(HarmonicAssistantRhythm.notesForChord(
        pitches: pitches,
        startBeat: beat,
        slotBeats: block.durationBeats,
        spec: rhythmSpec,
      ));
      previous = pitches;
      beat += block.durationBeats;
    }
    return out;
  }
}
