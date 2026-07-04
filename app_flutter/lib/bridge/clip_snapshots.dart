import 'timeline_clip.dart';

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
    );
  }
}

class MidiClipTakeSnapshot {
  const MidiClipTakeSnapshot({
    required this.id,
    required this.name,
    required this.startBeatOffset,
    required this.lengthBeats,
    required this.notes,
  });

  final String id;
  final String name;
  final double startBeatOffset;
  final double lengthBeats;
  final List<MidiNoteSnapshot> notes;

  factory MidiClipTakeSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final notesRaw = map['notes'] as List<dynamic>? ?? [];
    return MidiClipTakeSnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Take',
      startBeatOffset: (map['startBeatOffset'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 0.0,
      notes: notesRaw
          .map((n) => MidiNoteSnapshot.fromMap(n as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}

class MidiClipTakeRegionSnapshot {
  const MidiClipTakeRegionSnapshot({
    required this.startBeat,
    required this.endBeat,
    required this.takeId,
    required this.sourceStart,
  });

  final double startBeat;
  final double endBeat;
  final String takeId;
  final double sourceStart;

  factory MidiClipTakeRegionSnapshot.fromMap(Map<dynamic, dynamic> map) =>
      MidiClipTakeRegionSnapshot(
        startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
        endBeat: (map['endBeat'] as num?)?.toDouble() ?? 0.0,
        takeId: map['takeId'] as String? ?? '',
        sourceStart: (map['sourceStart'] as num?)?.toDouble() ?? 0.0,
      );
}

class MidiNoteSnapshot {
  const MidiNoteSnapshot({
    required this.pitch,
    required this.startBeat,
    required this.durationBeats,
    required this.velocity,
  });

  final int pitch;
  final double startBeat;
  final double durationBeats;
  final double velocity;

  factory MidiNoteSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return MidiNoteSnapshot(
      pitch: (map['pitch'] as num?)?.toInt() ?? 60,
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      durationBeats: (map['durationBeats'] as num?)?.toDouble() ?? 1.0,
      velocity: (map['velocity'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

/// Arrangement clip with sample/audio payload.
class SampleClipTakeSnapshot {
  const SampleClipTakeSnapshot({
    required this.id,
    required this.sampleId,
    required this.name,
    required this.startBeatOffset,
    required this.lengthBeats,
  });

  final String id;
  final String sampleId;
  final String name;
  final double startBeatOffset;
  final double lengthBeats;

  factory SampleClipTakeSnapshot.fromMap(Map<dynamic, dynamic> map) =>
      SampleClipTakeSnapshot(
        id: map['id'] as String? ?? '',
        sampleId: map['sampleId'] as String? ?? '',
        name: map['name'] as String? ?? 'Take',
        startBeatOffset: (map['startBeatOffset'] as num?)?.toDouble() ?? 0.0,
        lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 0.0,
      );
}

class SampleClipTakeRegionSnapshot {
  const SampleClipTakeRegionSnapshot({
    required this.startBeat,
    required this.endBeat,
    required this.takeId,
    required this.sourceStart,
  });

  final double startBeat;
  final double endBeat;
  final String takeId;
  final double sourceStart;

  factory SampleClipTakeRegionSnapshot.fromMap(Map<dynamic, dynamic> map) =>
      SampleClipTakeRegionSnapshot(
        startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
        endBeat: (map['endBeat'] as num?)?.toDouble() ?? 0.0,
        takeId: map['takeId'] as String? ?? '',
        sourceStart: (map['sourceStart'] as num?)?.toDouble() ?? 0.0,
      );
}

class SampleClipSnapshot implements ClipTimelineSpan {
  const SampleClipSnapshot({
    required this.id,
    required this.sampleId,
    required this.sampleName,
    required this.startBeat,
    required this.lengthBeats,
    required this.waveformPeaks,
    this.naturalLengthBeats,
    this.loopContent = false,
    this.sourceStart = 0,
    this.sourceEnd = 1,
    this.gain = 1,
    this.fadeIn = 0,
    this.fadeOut = 0,
    this.fadeInCurve = .5,
    this.fadeOutCurve = .5,
    this.reversed = false,
    this.warpRepitch = false,
    this.sliceMarkers = const [],
    this.takes = const [],
    this.activeTakeRegions = const [],
  });

  @override
  final String id;

  @override
  final double startBeat;

  @override
  final double lengthBeats;

  @override
  ClipContentKind get kind => ClipContentKind.sample;

  final String sampleId;
  final String sampleName;
  final List<double> waveformPeaks;

  /// Length of the waveform's source region in beats, captured at clip
  /// creation. Never modified by resize. The arranger uses this to render
  /// the waveform at its natural density — clipped when the clip is shorter
  /// than the source, anchored with trailing empty space when longer.
  ///
  /// Defaults to [lengthBeats] when not supplied (legacy snapshots / unit
  /// tests that don't round-trip through the engine).
  final double? naturalLengthBeats;

  /// When true, sample content repeats within the clip's timeline span.
  final bool loopContent;
  final double sourceStart;
  final double sourceEnd;
  final double gain;
  final double fadeIn;
  final double fadeOut;
  final double fadeInCurve;
  final double fadeOutCurve;
  final bool reversed;
  final bool warpRepitch;
  final List<double> sliceMarkers;
  final List<SampleClipTakeSnapshot> takes;
  final List<SampleClipTakeRegionSnapshot> activeTakeRegions;

  @override
  double get endBeat => startBeat + lengthBeats;

  /// Resolved natural length — falls back to current length when missing.
  double get effectiveNaturalLengthBeats => naturalLengthBeats ?? lengthBeats;

  /// Arrangement playback window for sample clips (waveform source length is
  /// [effectiveNaturalLengthBeats]).
  double get editorContentLengthBeats => lengthBeats;

  /// Beats consumed playing the current trim window once at native rate.
  double playbackContentLengthBeats({
    double? sourceStart,
    double? sourceEnd,
    bool? warpRepitch,
  }) =>
      sampleClipPlaybackContentLengthBeats(
        lengthBeats: lengthBeats,
        naturalLengthBeats: effectiveNaturalLengthBeats,
        sourceStart: sourceStart ?? this.sourceStart,
        sourceEnd: sourceEnd ?? this.sourceEnd,
        warpRepitch: warpRepitch ?? this.warpRepitch,
      );

  factory SampleClipSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final peaksRaw = map['waveformPeaks'] as List<dynamic>? ?? [];
    final takesRaw = map['takes'] as List<dynamic>? ?? const [];
    final takeRegionsRaw =
        map['activeTakeRegions'] as List<dynamic>? ?? const [];
    final lengthBeats = (map['lengthBeats'] as num?)?.toDouble() ?? 4.0;
    return SampleClipSnapshot(
      id: map['id'] as String? ?? '',
      sampleId: map['sampleId'] as String? ?? '',
      sampleName: map['sampleName'] as String? ?? '',
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: lengthBeats,
      waveformPeaks: peaksRaw.map((p) => (p as num).toDouble()).toList(),
      naturalLengthBeats:
          (map['naturalLengthBeats'] as num?)?.toDouble() ?? lengthBeats,
      loopContent: snapshotBool(map['loopContent']),
      sourceStart: (map['sourceStart'] as num?)?.toDouble() ?? 0,
      sourceEnd: (map['sourceEnd'] as num?)?.toDouble() ?? 1,
      gain: (map['gain'] as num?)?.toDouble() ?? 1,
      fadeIn: (map['fadeIn'] as num?)?.toDouble() ?? 0,
      fadeOut: (map['fadeOut'] as num?)?.toDouble() ?? 0,
      fadeInCurve: (map['fadeInCurve'] as num?)?.toDouble() ?? .5,
      fadeOutCurve: (map['fadeOutCurve'] as num?)?.toDouble() ?? .5,
      reversed: snapshotBool(map['reversed']),
      warpRepitch: snapshotBool(map['warpRepitch']),
      sliceMarkers: (map['sliceMarkers'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toDouble())
          .toList(),
      takes: takesRaw
          .map((value) =>
              SampleClipTakeSnapshot.fromMap(value as Map<dynamic, dynamic>))
          .toList(),
      activeTakeRegions: takeRegionsRaw
          .map((value) => SampleClipTakeRegionSnapshot.fromMap(
              value as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  SampleClipSnapshot copyWith({
    String? id,
    String? sampleId,
    String? sampleName,
    double? startBeat,
    double? lengthBeats,
    List<double>? waveformPeaks,
    double? naturalLengthBeats,
    bool? loopContent,
    double? sourceStart,
    double? sourceEnd,
    double? gain,
    double? fadeIn,
    double? fadeOut,
    double? fadeInCurve,
    double? fadeOutCurve,
    bool? reversed,
    bool? warpRepitch,
    List<double>? sliceMarkers,
    List<SampleClipTakeSnapshot>? takes,
    List<SampleClipTakeRegionSnapshot>? activeTakeRegions,
  }) {
    return SampleClipSnapshot(
      id: id ?? this.id,
      sampleId: sampleId ?? this.sampleId,
      sampleName: sampleName ?? this.sampleName,
      startBeat: startBeat ?? this.startBeat,
      lengthBeats: lengthBeats ?? this.lengthBeats,
      waveformPeaks: waveformPeaks ?? this.waveformPeaks,
      naturalLengthBeats: naturalLengthBeats ?? this.naturalLengthBeats,
      loopContent: loopContent ?? this.loopContent,
      sourceStart: sourceStart ?? this.sourceStart,
      sourceEnd: sourceEnd ?? this.sourceEnd,
      gain: gain ?? this.gain,
      fadeIn: fadeIn ?? this.fadeIn,
      fadeOut: fadeOut ?? this.fadeOut,
      fadeInCurve: fadeInCurve ?? this.fadeInCurve,
      fadeOutCurve: fadeOutCurve ?? this.fadeOutCurve,
      reversed: reversed ?? this.reversed,
      warpRepitch: warpRepitch ?? this.warpRepitch,
      sliceMarkers: sliceMarkers ?? this.sliceMarkers,
      takes: takes ?? this.takes,
      activeTakeRegions: activeTakeRegions ?? this.activeTakeRegions,
    );
  }
}

class AutomationPointSnapshot {
  const AutomationPointSnapshot({
    required this.beat,
    required this.value,
  });

  final double beat;
  final double value;

  factory AutomationPointSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return AutomationPointSnapshot(
      beat: (map['beat'] as num?)?.toDouble() ?? 0.0,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'beat': beat,
        'value': value,
      };
}

/// Parameter automation clip on a track timeline.
///
/// The clip is laid out on its [homeTrackId] (independent of where the
/// target device lives) and automates a parameter on the device identified
/// by [deviceId] / [paramId]. The two relationships are independent — the
/// home track is a layout choice, the target device is a routing choice.
class AutomationClipSnapshot implements ClipTimelineSpan {
  const AutomationClipSnapshot({
    required this.id,
    required this.homeTrackId,
    required this.startBeat,
    required this.lengthBeats,
    required this.deviceId,
    required this.paramId,
    required this.points,
    this.naturalLengthBeats,
    this.loopContent = false,
  });

  @override
  final String id;

  /// Track the clip is rendered on in the arrangement view. Set at create
  /// time; the target device (deviceId/paramId) may live on any track,
  /// including this one.
  final String homeTrackId;

  @override
  final double startBeat;

  @override
  final double lengthBeats;

  @override
  ClipContentKind get kind => ClipContentKind.automation;

  final String deviceId;
  final String paramId;
  final List<AutomationPointSnapshot> points;

  final double? naturalLengthBeats;
  final bool loopContent;

  bool get isLinked => deviceId.isNotEmpty && paramId.isNotEmpty;

  @override
  double get endBeat => startBeat + lengthBeats;

  double get effectiveNaturalLengthBeats => naturalLengthBeats ?? lengthBeats;

  /// Grid span for automation editors — authored content length.
  double get editorContentLengthBeats => effectiveNaturalLengthBeats;

  double get loopContentLengthBeats => effectiveNaturalLengthBeats;

  String get linkLabel => isLinked ? _humanizeParamId(paramId) : 'Link';

  static String linkLabelForParam(String paramId) => _humanizeParamId(paramId);

  static String _humanizeParamId(String paramId) {
    return switch (paramId) {
      'filterCutoff' => 'Filter',
      'filterQ' => 'Resonance',
      'gain' => 'Gain',
      'attack' => 'Attack',
      'decay' => 'Decay',
      'sustain' => 'Sustain',
      'release' => 'Release',
      _ => paramId,
    };
  }

  factory AutomationClipSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final pointsRaw = map['points'] as List<dynamic>? ?? [];
    final lengthBeats = (map['lengthBeats'] as num?)?.toDouble() ?? 4.0;
    return AutomationClipSnapshot(
      id: map['id'] as String? ?? '',
      homeTrackId: map['homeTrackId'] as String? ?? '',
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: lengthBeats,
      naturalLengthBeats:
          (map['naturalLengthBeats'] as num?)?.toDouble() ?? lengthBeats,
      loopContent: snapshotBool(map['loopContent']),
      deviceId: map['deviceId'] as String? ?? '',
      paramId: map['paramId'] as String? ?? '',
      points: pointsRaw
          .map((p) =>
              AutomationPointSnapshot.fromMap(p as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  AutomationClipSnapshot copyWith({
    String? id,
    String? homeTrackId,
    double? startBeat,
    double? lengthBeats,
    double? naturalLengthBeats,
    bool? loopContent,
    String? deviceId,
    String? paramId,
    List<AutomationPointSnapshot>? points,
  }) {
    return AutomationClipSnapshot(
      id: id ?? this.id,
      homeTrackId: homeTrackId ?? this.homeTrackId,
      startBeat: startBeat ?? this.startBeat,
      lengthBeats: lengthBeats ?? this.lengthBeats,
      naturalLengthBeats: naturalLengthBeats ?? this.naturalLengthBeats,
      loopContent: loopContent ?? this.loopContent,
      deviceId: deviceId ?? this.deviceId,
      paramId: paramId ?? this.paramId,
      points: points ?? this.points,
    );
  }
}

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
