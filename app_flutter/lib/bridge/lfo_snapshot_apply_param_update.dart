part of 'project_snapshot.dart';

extension LfoSnapshotApplyparamupdateOperation on LfoSnapshot {
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
        return copyWith(
            curveBpPositions: [for (var i = 0; i < value.round().clamp(2, 64); i++) i < curveBpPositions.length ? curveBpPositions[i] : (i / (value - 1))]);
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
}
