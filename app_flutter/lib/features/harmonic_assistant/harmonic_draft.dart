import '../play/play_scale.dart';
import 'harmonic_assistant_spec.dart';

/// One chord block on the Harmonic canvas.
class HarmonicChordBlock {
  const HarmonicChordBlock({
    required this.degree,
    this.durationBeats = 4,
    this.inversion = -1,
    this.pitchOffset = 0,
  });

  final int degree;
  final double durationBeats;
  final int inversion;

  /// Semitone transpose for this chord group (move up/down on roll).
  final int pitchOffset;

  HarmonicChordBlock copyWith({
    int? degree,
    double? durationBeats,
    int? inversion,
    int? pitchOffset,
  }) {
    return HarmonicChordBlock(
      degree: degree ?? this.degree,
      durationBeats: durationBeats ?? this.durationBeats,
      inversion: inversion ?? this.inversion,
      pitchOffset: pitchOffset ?? this.pitchOffset,
    );
  }
}

/// In-editor draft progression (not yet committed to clip notes).
class HarmonicDraft {
  HarmonicDraft({
    required this.scale,
    required this.rootPitchClass,
    List<HarmonicChordBlock>? blocks,
    this.sevenths = false,
    this.octaveCenter = 60,
    this.width = HarmonicVoicingWidth.close,
    this.voiceLeadStrength = 0.7,
    this.rhythm = HarmonicRhythmPattern.block,
    this.gate = 1.0,
    this.strumBeats = 0.05,
    this.arpSubdivisions = 4,
    this.velocity = 100,
  }) : blocks = List.of(blocks ?? const []);

  PlayScale scale;
  int rootPitchClass;
  List<HarmonicChordBlock> blocks;
  bool sevenths;
  int octaveCenter;
  HarmonicVoicingWidth width;
  double voiceLeadStrength;
  HarmonicRhythmPattern rhythm;
  double gate;
  double strumBeats;
  int arpSubdivisions;
  double velocity;

  double get totalBeats => blocks.fold<double>(
        0,
        (sum, b) => sum + b.durationBeats,
      );

  /// Start beat for each block (parallel to [blocks]).
  List<double> get blockStarts {
    final starts = <double>[];
    var beat = 0.0;
    for (final b in blocks) {
      starts.add(beat);
      beat += b.durationBeats;
    }
    return starts;
  }

  HarmonicDraft copy() {
    return HarmonicDraft(
      scale: scale,
      rootPitchClass: rootPitchClass,
      blocks: [for (final b in blocks) b.copyWith()],
      sevenths: sevenths,
      octaveCenter: octaveCenter,
      width: width,
      voiceLeadStrength: voiceLeadStrength,
      rhythm: rhythm,
      gate: gate,
      strumBeats: strumBeats,
      arpSubdivisions: arpSubdivisions,
      velocity: velocity,
    );
  }
}
