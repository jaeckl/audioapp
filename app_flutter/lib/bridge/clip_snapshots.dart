import 'timeline_clip.dart';

/// MIDI and sample clip snapshots with shared timeline span fields.
class MidiClipSnapshot implements ClipTimelineSpan {
  const MidiClipSnapshot({
    required this.id,
    required this.startBeat,
    required this.lengthBeats,
    required this.notes,
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

  double get endBeat => startBeat + lengthBeats;

  factory MidiClipSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final notesRaw = map['notes'] as List<dynamic>? ?? [];
    return MidiClipSnapshot(
      id: map['id'] as String? ?? '',
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 4.0,
      notes: notesRaw
          .map((n) => MidiNoteSnapshot.fromMap(n as Map<dynamic, dynamic>))
          .toList(),
    );
  }
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
class SampleClipSnapshot implements ClipTimelineSpan {
  const SampleClipSnapshot({
    required this.id,
    required this.sampleId,
    required this.sampleName,
    required this.startBeat,
    required this.lengthBeats,
    required this.waveformPeaks,
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

  double get endBeat => startBeat + lengthBeats;

  factory SampleClipSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final peaksRaw = map['waveformPeaks'] as List<dynamic>? ?? [];
    return SampleClipSnapshot(
      id: map['id'] as String? ?? '',
      sampleId: map['sampleId'] as String? ?? '',
      sampleName: map['sampleName'] as String? ?? '',
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 4.0,
      waveformPeaks: peaksRaw.map((p) => (p as num).toDouble()).toList(),
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

  bool get isLinked => deviceId.isNotEmpty && paramId.isNotEmpty;

  double get endBeat => startBeat + lengthBeats;

  String get linkLabel =>
      isLinked ? _humanizeParamId(paramId) : 'Link';

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
    return AutomationClipSnapshot(
      id: map['id'] as String? ?? '',
      homeTrackId: map['homeTrackId'] as String? ?? '',
      startBeat: (map['startBeat'] as num?)?.toDouble() ?? 0.0,
      lengthBeats: (map['lengthBeats'] as num?)?.toDouble() ?? 4.0,
      deviceId: map['deviceId'] as String? ?? '',
      paramId: map['paramId'] as String? ?? '',
      points: pointsRaw
          .map((p) => AutomationPointSnapshot.fromMap(p as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}
