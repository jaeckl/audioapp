part of 'project_snapshot.dart';

class LfoSnapshot {
  const LfoSnapshot({
    required this.id,
    this.type = 'lfo',
    this.retrigger = 0,
    this.waveform = 0,
    this.rate = 1.0,
    this.syncDivision = 0,
    this.phase = 0.0,
    this.polarity = 0,
    this.attack = 0.1,
    this.decay = 0.25,
    this.sustain = 0.7,
    this.release = 0.35,
    this.name = '',
    this.curveType = 0,
    this.hold = 0.0,
    this.delay = 0.0,
    this.attackCurve = 0.5,
    this.decayCurve = 0.5,
    this.releaseCurve = 0.5,
    this.analogMode = 0,
    this.noteFollow = 0,
    this.morph = 0.0,
    this.spread = 0.5,
    this.smoothing = 0.0,
    this.sequencerSteps = 16,
    this.sequencerDirection = 0,
    this.sequencerShape = 0,
    this.stepValues = const [],
    this.curveBpPositions = const [0.0, 1.0],
    this.curveBpValues = const [0.0, 1.0],
    this.curveBpShapes = const [0, 0],
  });

  final int id;

  /// "lfo" or "envelope" — type string from engine IModulatorType::typeId().
  final String type;
  final int retrigger;
  final int waveform;
  final double rate;
  final int syncDivision;
  final double phase;
  final int polarity;
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final String name;
  final int curveType;
  final double hold;
  final double delay;
  final double attackCurve;
  final double decayCurve;
  final double releaseCurve;
  final int analogMode;
  final int noteFollow;
  final double morph;
  final double spread;
  final double smoothing;
  final int sequencerSteps;
  final int sequencerDirection;
  final int sequencerShape;
  final List<double> stepValues;
  final List<double> curveBpPositions;
  final List<double> curveBpValues;
  final List<int> curveBpShapes;

  int get modulatorType => type == 'envelope'
      ? 1
      : type == 'random_generator'
          ? 2
          : type == 'sequencer'
              ? 3
              : type == 'curve'
                  ? 4
                  : 0;

  factory LfoSnapshot.fromMap(Map<dynamic, dynamic> map) {
    // New style: type field from IModulatorType::paramsToVar()
    final typeStr = map['type'] as String? ?? '';
    if (typeStr == 'envelope') {
      return LfoSnapshot(
        id: (map['id'] as num?)?.toInt() ?? 0,
        type: 'envelope',
        attack: (map['attack'] as num?)?.toDouble() ?? 0.08,
        decay: (map['decay'] as num?)?.toDouble() ?? 0.22,
        sustain: (map['sustain'] as num?)?.toDouble() ?? 0.65,
        release: (map['release'] as num?)?.toDouble() ?? 0.28,
        curveType: (map['curveType'] as num?)?.toInt() ?? 0,
        hold: (map['hold'] as num?)?.toDouble() ?? 0.0,
        delay: (map['delay'] as num?)?.toDouble() ?? 0.0,
        attackCurve: (map['attackCurve'] as num?)?.toDouble() ?? 0.5,
        decayCurve: (map['decayCurve'] as num?)?.toDouble() ?? 0.5,
        releaseCurve: (map['releaseCurve'] as num?)?.toDouble() ?? 0.5,
        analogMode: (map['analogMode'] as num?)?.toInt() ?? 0,
        noteFollow: (map['noteFollow'] as num?)?.toInt() ?? 0,
      );
    }
    if (typeStr == 'sequencer') {
      final stepCount = (map['stepCount'] as num?)?.toInt() ?? 16;
      final steps = <double>[];
      for (var i = 0; i < stepCount; i++) {
        final key = 'step_$i';
        final val = map[key] as num?;
        steps.add(val?.toDouble() ?? 0.5);
      }
      return LfoSnapshot(
        id: (map['id'] as num?)?.toInt() ?? 0,
        type: 'sequencer',
        sequencerSteps: stepCount,
        sequencerDirection: (map['direction'] as num?)?.toInt() ?? 0,
        sequencerShape: (map['shape'] as num?)?.toInt() ?? 0,
        retrigger: (map['retrigger'] as num?)?.toInt() ?? 1,
        rate: (map['rate'] as num?)?.toDouble() ?? 0.5,
        syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 3,
        polarity: (map['polarity'] as num?)?.toInt() ?? 0,
        smoothing: (map['smoothing'] as num?)?.toDouble() ?? 0.0,
        stepValues: steps,
      );
    }
    if (typeStr == 'curve') {
      final bpCount = (map['breakpointCount'] as num?)?.toInt() ?? 2;
      final positions = <double>[];
      final values = <double>[];
      final shapes = <int>[];
      for (var i = 0; i < bpCount; i++) {
        final posKey = 'bp_${i}_pos';
        final valKey = 'bp_${i}_val';
        final shapeKey = 'bp_${i}_shape';
        positions.add((map[posKey] as num?)?.toDouble() ??
            (i / (bpCount - 1).clamp(1, bpCount - 1)));
        values.add((map[valKey] as num?)?.toDouble() ?? 0.0);
        shapes.add((map[shapeKey] as num?)?.toInt() ?? 0);
      }
      return LfoSnapshot(
        id: (map['id'] as num?)?.toInt() ?? 0,
        type: 'curve',
        rate: (map['rate'] as num?)?.toDouble() ?? 0.5,
        retrigger: (map['retrigger'] as num?)?.toInt() ?? 1,
        syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 3,
        polarity: (map['polarity'] as num?)?.toInt() ?? 0,
        smoothing: (map['smoothing'] as num?)?.toDouble() ?? 0.0,
        curveBpPositions: positions,
        curveBpValues: values,
        curveBpShapes: shapes,
      );
    }
    // LFO or default (fallback for old-format JSON with numeric modulatorType)
    return LfoSnapshot(
      id: (map['id'] as num?)?.toInt() ?? 0,
      type: typeStr.isNotEmpty ? typeStr : 'lfo',
      retrigger: (map['retrigger'] as num?)?.toInt() ?? 0,
      waveform: (map['waveform'] as num?)?.toInt() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 1.0,
      syncDivision: (map['syncDivision'] as num?)?.toInt() ?? 0,
      phase: (map['phase'] as num?)?.toDouble() ?? 0.0,
      polarity: (map['polarity'] as num?)?.toInt() ?? 0,
      attack: (map['attack'] as num?)?.toDouble() ?? 0.1,
      decay: (map['decay'] as num?)?.toDouble() ?? 0.25,
      sustain: (map['sustain'] as num?)?.toDouble() ?? 0.7,
      release: (map['release'] as num?)?.toDouble() ?? 0.35,
      curveType: (map['curveType'] as num?)?.toInt() ?? 0,
      hold: (map['hold'] as num?)?.toDouble() ?? 0.0,
      delay: (map['delay'] as num?)?.toDouble() ?? 0.0,
      attackCurve: (map['attackCurve'] as num?)?.toDouble() ?? 0.5,
      decayCurve: (map['decayCurve'] as num?)?.toDouble() ?? 0.5,
      releaseCurve: (map['releaseCurve'] as num?)?.toDouble() ?? 0.5,
      analogMode: (map['analogMode'] as num?)?.toInt() ?? 0,
      noteFollow: (map['noteFollow'] as num?)?.toInt() ?? 0,
      morph: (map['morph'] as num?)?.toDouble() ?? 0.0,
      spread: (map['spread'] as num?)?.toDouble() ?? 0.5,
      smoothing: (map['smoothing'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static const List<String> waveformNames = [
    'Sine',
    'Tri',
    'Saw',
    'Square',
    'Ramp',
  ];

  String get waveformName => waveform >= 0 && waveform < waveformNames.length
      ? waveformNames[waveform]
      : 'Sine';

  /// Optimistic param update: maps param name → copyWith field.
  /// Returns a new [LfoSnapshot] with that field changed.
  LfoSnapshot applyParamUpdate(String param, double value) {
    switch (param) {
      case 'retrigger':
        return copyWith(retrigger: value.round());
      case 'waveform':
        return copyWith(waveform: value.round());
      case 'rate':
        return copyWith(rate: value);
      case 'syncDivision':
        return copyWith(syncDivision: value.round());
      case 'phase':
        return copyWith(phase: value);
      case 'polarity':
        return copyWith(polarity: value.round());
      case 'attack':
        return copyWith(attack: value);
      case 'decay':
        return copyWith(decay: value);
      case 'sustain':
        return copyWith(sustain: value);
      case 'release':
        return copyWith(release: value);
      case 'curveType':
        return copyWith(curveType: value.round());
      case 'hold':
        return copyWith(hold: value);
      case 'delay':
        return copyWith(delay: value);
      case 'attackCurve':
        return copyWith(attackCurve: value);
      case 'decayCurve':
        return copyWith(decayCurve: value);
      case 'releaseCurve':
        return copyWith(releaseCurve: value);
      case 'analogMode':
        return copyWith(analogMode: value.round());
      case 'noteFollow':
        return copyWith(noteFollow: value.round());
      case 'morph':
        return copyWith(morph: value);
      case 'spread':
        return copyWith(spread: value);
      case 'smoothing':
        return copyWith(smoothing: value);
      case 'steps':
        return copyWith(sequencerSteps: value.round().clamp(1, 32));
      case 'direction':
        return copyWith(sequencerDirection: value.round().clamp(0, 3));
      case 'shape':
        return copyWith(sequencerShape: value.round().clamp(0, 2));
      case 'breakpointCount':
        return copyWith(curveBpPositions: [
          for (var i = 0; i < value.round().clamp(2, 64); i++)
            i < curveBpPositions.length
                ? curveBpPositions[i]
                : (i / (value - 1))
        ]);
      default:
        if (param.startsWith('bp_')) {
          // bp_IDX_pos, bp_IDX_val, bp_IDX_shape
          final parts = param.split('_');
          if (parts.length == 3) {
            final idx = int.tryParse(parts[1]);
            if (idx != null && idx >= 0 && idx < 64) {
              final attr = parts[2];
              if (attr == 'pos') {
                final newVals = [...curveBpPositions];
                while (newVals.length <= idx) {
                  newVals.add(0.5);
                }
                newVals[idx] = value.clamp(0.0, 1.0);
                return copyWith(curveBpPositions: newVals);
              }
              if (attr == 'val') {
                final newVals = [...curveBpValues];
                while (newVals.length <= idx) {
                  newVals.add(0.0);
                }
                newVals[idx] = value.clamp(-1.0, 1.0);
                return copyWith(curveBpValues: newVals);
              }
              if (attr == 'shape') {
                final newVals = [...curveBpShapes];
                while (newVals.length <= idx) {
                  newVals.add(0);
                }
                newVals[idx] = value.round().clamp(0, 2);
                return copyWith(curveBpShapes: newVals);
              }
            }
          }
        }
        if (param.startsWith('step_')) {
          final idx = int.tryParse(param.substring(5));
          if (idx != null && idx >= 0 && idx < stepValues.length) {
            final newSteps = [...stepValues];
            newSteps[idx] = value.clamp(0.0, 1.0);
            return copyWith(stepValues: newSteps);
          }
        }
        return this;
    }
  }

  LfoSnapshot withStepValue(int index, double value) {
    final newList = List<double>.of(stepValues);
    if (index >= 0 && index < newList.length) {
      newList[index] = value.clamp(0.0, 1.0);
    }
    return copyWith(stepValues: newList);
  }

  LfoSnapshot copyWith({
    int? id,
    String? type,
    int? retrigger,
    int? waveform,
    double? rate,
    int? syncDivision,
    double? phase,
    int? polarity,
    double? attack,
    double? decay,
    double? sustain,
    double? release,
    String? name,
    int? curveType,
    double? hold,
    double? delay,
    double? attackCurve,
    double? decayCurve,
    double? releaseCurve,
    int? analogMode,
    int? noteFollow,
    double? morph,
    double? spread,
    double? smoothing,
    int? sequencerSteps,
    int? sequencerDirection,
    int? sequencerShape,
    List<double>? stepValues,
    List<double>? curveBpPositions,
    List<double>? curveBpValues,
    List<int>? curveBpShapes,
  }) {
    return LfoSnapshot(
      id: id ?? this.id,
      type: type ?? this.type,
      retrigger: retrigger ?? this.retrigger,
      waveform: waveform ?? this.waveform,
      rate: rate ?? this.rate,
      syncDivision: syncDivision ?? this.syncDivision,
      phase: phase ?? this.phase,
      polarity: polarity ?? this.polarity,
      attack: attack ?? this.attack,
      decay: decay ?? this.decay,
      sustain: sustain ?? this.sustain,
      release: release ?? this.release,
      name: name ?? this.name,
      curveType: curveType ?? this.curveType,
      hold: hold ?? this.hold,
      delay: delay ?? this.delay,
      attackCurve: attackCurve ?? this.attackCurve,
      decayCurve: decayCurve ?? this.decayCurve,
      releaseCurve: releaseCurve ?? this.releaseCurve,
      analogMode: analogMode ?? this.analogMode,
      noteFollow: noteFollow ?? this.noteFollow,
      morph: morph ?? this.morph,
      spread: spread ?? this.spread,
      smoothing: smoothing ?? this.smoothing,
      sequencerSteps: sequencerSteps ?? this.sequencerSteps,
      sequencerDirection: sequencerDirection ?? this.sequencerDirection,
      sequencerShape: sequencerShape ?? this.sequencerShape,
      stepValues: stepValues ?? this.stepValues,
      curveBpPositions: curveBpPositions ?? this.curveBpPositions,
      curveBpValues: curveBpValues ?? this.curveBpValues,
      curveBpShapes: curveBpShapes ?? this.curveBpShapes,
    );
  }
}
