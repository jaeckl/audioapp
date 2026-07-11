part of 'clip_snapshots.dart';

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
