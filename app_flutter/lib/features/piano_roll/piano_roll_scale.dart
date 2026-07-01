import '../../bridge/project_snapshot.dart';
import '../play/play_deck_layout.dart';
import '../play/play_scale.dart';

class PianoRollScaleSettings {
  const PianoRollScaleSettings({
    this.rootPitchClass = 0,
    this.scale = PlayScale.major,
    this.highlight = false,
    this.snapToScale = false,
    this.chordQuality = ChordQuality.off,
  });

  final int rootPitchClass;
  final PlayScale scale;
  final bool highlight;
  final bool snapToScale;
  final ChordQuality chordQuality;

  factory PianoRollScaleSettings.fromClip(MidiClipSnapshot clip) {
    return PianoRollScaleSettings(
      rootPitchClass: clip.editorScaleRoot,
      scale: PlayScale.byId(clip.editorScaleId),
      highlight: clip.editorScaleHighlight,
      snapToScale: clip.editorScaleSnap,
      chordQuality: chordQualityById(clip.editorChordQuality),
    );
  }

  PianoRollScaleSettings copyWith({
    int? rootPitchClass,
    PlayScale? scale,
    bool? highlight,
    bool? snapToScale,
    ChordQuality? chordQuality,
  }) {
    return PianoRollScaleSettings(
      rootPitchClass: rootPitchClass ?? this.rootPitchClass,
      scale: scale ?? this.scale,
      highlight: highlight ?? this.highlight,
      snapToScale: snapToScale ?? this.snapToScale,
      chordQuality: chordQuality ?? this.chordQuality,
    );
  }

  bool isPitchInScale(int pitch) {
    if (scale.id == PlayScale.chromatic.id) return true;
    final relative = (pitch - rootPitchClass) % 12;
    return scale.intervals.contains(relative < 0 ? relative + 12 : relative);
  }

  int snapPitch(int pitch, {required int minPitch, required int maxPitch}) {
    if (!snapToScale || isPitchInScale(pitch)) {
      return pitch.clamp(minPitch, maxPitch);
    }
    for (var delta = 1; delta <= 12; delta++) {
      final up = pitch + delta;
      if (up <= maxPitch && isPitchInScale(up)) return up;
      final down = pitch - delta;
      if (down >= minPitch && isPitchInScale(down)) return down;
    }
    return pitch.clamp(minPitch, maxPitch);
  }

  List<int> chordPitches(int root,
      {required int minPitch, required int maxPitch}) {
    final snappedRoot = snapPitch(root, minPitch: minPitch, maxPitch: maxPitch);
    return [
      for (final step in chordQuality.intervals)
        (snappedRoot + step).clamp(minPitch, maxPitch),
    ].toSet().toList()
      ..sort();
  }

  String get rootLabel => PlayScale.noteNames[rootPitchClass % 12];

  Map<String, Object> toBridgeArgs(String clipId) => {
        'clipId': clipId,
        'rootPitchClass': rootPitchClass,
        'scaleId': scale.id,
        'highlight': highlight,
        'snapToScale': snapToScale,
        'chordQuality': chordQuality.name,
      };

  @override
  bool operator ==(Object other) {
    return other is PianoRollScaleSettings &&
        other.rootPitchClass == rootPitchClass &&
        other.scale.id == scale.id &&
        other.highlight == highlight &&
        other.snapToScale == snapToScale &&
        other.chordQuality == chordQuality;
  }

  @override
  int get hashCode => Object.hash(
        rootPitchClass,
        scale.id,
        highlight,
        snapToScale,
        chordQuality,
      );
}

ChordQuality chordQualityById(String id) {
  for (final quality in ChordQuality.values) {
    if (quality.name == id) return quality;
  }
  return ChordQuality.off;
}
