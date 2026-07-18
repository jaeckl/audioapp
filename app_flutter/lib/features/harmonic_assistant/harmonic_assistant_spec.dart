import '../music_theory/progression_templates.dart';
import '../play/play_scale.dart';

enum HarmonicRhythmPattern { block, strum, arpUp, arpDown, arpBroken }

enum HarmonicVoicingWidth { close, open }

enum HarmonicCommitMode { insertAtPlayhead, replaceSelection, replaceRange }

/// Parameters for one deterministic progression generation.
class HarmonicAssistantSpec {
  const HarmonicAssistantSpec({
    required this.scale,
    required this.rootPitchClass,
    required this.degrees,
    this.beatsPerChord = 4,
    this.repeats = 1,
    this.sevenths = false,
    this.octaveCenter = 60,
    this.inversion = -1,
    this.width = HarmonicVoicingWidth.close,
    this.voiceLeadStrength = 0.7,
    this.rhythm = HarmonicRhythmPattern.block,
    this.gate = 1.0,
    this.strumBeats = 0.05,
    this.arpSubdivisions = 4,
    this.velocity = 100,
  });

  final PlayScale scale;
  final int rootPitchClass;
  final List<int> degrees;
  final double beatsPerChord;
  final int repeats;
  final bool sevenths;
  final int octaveCenter;
  final int inversion;
  final HarmonicVoicingWidth width;
  final double voiceLeadStrength;
  final HarmonicRhythmPattern rhythm;
  final double gate;
  final double strumBeats;
  final int arpSubdivisions;
  final double velocity;

  double get totalBeats =>
      degrees.isEmpty ? 0 : degrees.length * beatsPerChord * repeats;

  HarmonicAssistantSpec copyWith({
    PlayScale? scale,
    int? rootPitchClass,
    List<int>? degrees,
    double? beatsPerChord,
    int? repeats,
    bool? sevenths,
    int? octaveCenter,
    int? inversion,
    HarmonicVoicingWidth? width,
    double? voiceLeadStrength,
    HarmonicRhythmPattern? rhythm,
    double? gate,
    double? strumBeats,
    int? arpSubdivisions,
    double? velocity,
  }) {
    return HarmonicAssistantSpec(
      scale: scale ?? this.scale,
      rootPitchClass: rootPitchClass ?? this.rootPitchClass,
      degrees: degrees ?? this.degrees,
      beatsPerChord: beatsPerChord ?? this.beatsPerChord,
      repeats: repeats ?? this.repeats,
      sevenths: sevenths ?? this.sevenths,
      octaveCenter: octaveCenter ?? this.octaveCenter,
      inversion: inversion ?? this.inversion,
      width: width ?? this.width,
      voiceLeadStrength: voiceLeadStrength ?? this.voiceLeadStrength,
      rhythm: rhythm ?? this.rhythm,
      gate: gate ?? this.gate,
      strumBeats: strumBeats ?? this.strumBeats,
      arpSubdivisions: arpSubdivisions ?? this.arpSubdivisions,
      velocity: velocity ?? this.velocity,
    );
  }

  factory HarmonicAssistantSpec.fromScale({
    required PlayScale scale,
    required int rootPitchClass,
    ProgressionTemplate template = ProgressionTemplate.pop1564,
  }) {
    return HarmonicAssistantSpec(
      scale: scale,
      rootPitchClass: rootPitchClass,
      degrees: List.of(template.degrees),
    );
  }
}
