import 'timeline_clip.dart';

part 'midi_clip_take_snapshot.dart';
part 'midi_clip_take_region_snapshot.dart';
part 'midi_note_snapshot.dart';
part 'sample_clip_take_snapshot.dart';
part 'sample_clip_take_region_snapshot.dart';
part 'sample_clip_snapshot.dart';
part 'automation_point_snapshot.dart';
part 'automation_clip_snapshot.dart';

bool snapshotBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return fallback;
}

/// MIDI and sample clip snapshots with shared timeline span fields.
class MidiClipSnapshot implements ClipTimelineSpan {
  const MidiClipSnapshot({
    required this.id,
    required this.startBeat,
    required this.lengthBeats,
    required this.notes,
    this.takes = const [],
    this.activeTakeRegions = const [],
    this.compFlattened = false,
    this.naturalLengthBeats,
    this.loopContent = false,
    this.editorScaleRoot = 0,
    this.editorScaleId = 'major',
    this.editorScaleHighlight = false,
    this.editorScaleSnap = false,
    this.editorChordQuality = 'off',
  });

  @override
  final String id;

  @override
  final double startBeat;

  @override
  final double lengthBeats;

  @override
  ClipContentKind get kind => ClipContentKind.midi;

  final List<MidiNoteSnapshot> notes;
  final List<MidiClipTakeSnapshot> takes;
  final List<MidiClipTakeRegionSnapshot> activeTakeRegions;

  /// When true the comp is flattened: [notes] is authoritative and
  /// hand-editable, and the comp derivation no longer overwrites it.
  final bool compFlattened;

  /// Authored content length in beats. Set by editor range slider; not changed
  /// by arrangement resize (loop or one-shot).
  final double? naturalLengthBeats;

  /// When true, MIDI note content repeats within the clip's timeline span.
  final bool loopContent;

  final int editorScaleRoot;
  final String editorScaleId;
  final bool editorScaleHighlight;
  final bool editorScaleSnap;
  final String editorChordQuality;

  @override
  double get endBeat => startBeat + lengthBeats;

  /// Resolved natural length — falls back to current length when missing.
  double get effectiveNaturalLengthBeats => naturalLengthBeats ?? lengthBeats;

  /// Grid span for clip editors — always the authored content length.
  double get editorContentLengthBeats => effectiveNaturalLengthBeats;

  /// Beat span used to tile looped MIDI content in the arranger.
  double get loopContentLengthBeats => effectiveNaturalLengthBeats;

  factory MidiClipSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final notesRaw = map['notes'] as List<dynamic>? ?? [];
    final takesRaw = map['takes'] as List<dynamic>? ?? [];
    final regionsRaw = map['activeTakeRegions'] as List<dynamic>? ?? [];
    final lengthBeats = (map['lengthBeats'] as num?)?.toDouble() ?? 4.0;
    return MidiClipSnapshot(
      id: map['id'] as String? ?? '',
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: lengthBeats,
      naturalLengthBeats:
          (map['naturalLengthBeats'] as num?)?.toDouble() ?? lengthBeats,
      loopContent: snapshotBool(map['loopContent']),
      editorScaleRoot: (map['editorScaleRoot'] as num?)?.toInt() ?? 0,
      editorScaleId: map['editorScaleId'] as String? ?? 'major',
      editorScaleHighlight: snapshotBool(map['editorScaleHighlight']),
      editorScaleSnap: snapshotBool(map['editorScaleSnap']),
      editorChordQuality: map['editorChordQuality'] as String? ?? 'off',
      notes: notesRaw
          .map((n) => MidiNoteSnapshot.fromMap(n as Map<dynamic, dynamic>))
          .toList(),
      takes: takesRaw
          .map((t) => MidiClipTakeSnapshot.fromMap(t as Map<dynamic, dynamic>))
          .toList(),
      activeTakeRegions: regionsRaw
          .map((r) =>
              MidiClipTakeRegionSnapshot.fromMap(r as Map<dynamic, dynamic>))
          .toList(),
      compFlattened: map['compFlattened'] as bool? ?? false,
    );
  }

  MidiClipSnapshot copyWith({
    String? id,
    double? startBeat,
    double? lengthBeats,
    double? naturalLengthBeats,
    bool? loopContent,
    int? editorScaleRoot,
    String? editorScaleId,
    bool? editorScaleHighlight,
    bool? editorScaleSnap,
    String? editorChordQuality,
    List<MidiNoteSnapshot>? notes,
    List<MidiClipTakeSnapshot>? takes,
    List<MidiClipTakeRegionSnapshot>? activeTakeRegions,
    bool? compFlattened,
  }) {
    return MidiClipSnapshot(
      id: id ?? this.id,
      startBeat: startBeat ?? this.startBeat,
      lengthBeats: lengthBeats ?? this.lengthBeats,
      naturalLengthBeats: naturalLengthBeats ?? this.naturalLengthBeats,
      loopContent: loopContent ?? this.loopContent,
      editorScaleRoot: editorScaleRoot ?? this.editorScaleRoot,
      editorScaleId: editorScaleId ?? this.editorScaleId,
      editorScaleHighlight: editorScaleHighlight ?? this.editorScaleHighlight,
      editorScaleSnap: editorScaleSnap ?? this.editorScaleSnap,
      editorChordQuality: editorChordQuality ?? this.editorChordQuality,
      notes: notes ?? this.notes,
      takes: takes ?? this.takes,
      activeTakeRegions: activeTakeRegions ?? this.activeTakeRegions,
      compFlattened: compFlattened ?? this.compFlattened,
    );
  }
}

/// Arrangement clip with sample/audio payload.
/// Parameter automation clip on a track timeline.
///
/// The clip is laid out on its [homeTrackId] (independent of where the
/// target device lives) and automates a parameter on the device identified
/// by [deviceId] / [paramId]. The two relationships are independent — the
/// home track is a layout choice, the target device is a routing choice.
double sampleClipPlaybackContentLengthBeats({
  required double lengthBeats,
  required double naturalLengthBeats,
  required double sourceStart,
  required double sourceEnd,
  required bool warpRepitch,
}) {
  if (warpRepitch) return lengthBeats;
  final window = (sourceEnd - sourceStart).clamp(0.001, 1.0);
  return naturalLengthBeats * window;
}
