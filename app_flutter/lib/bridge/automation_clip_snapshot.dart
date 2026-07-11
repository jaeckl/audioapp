part of 'clip_snapshots.dart';

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
