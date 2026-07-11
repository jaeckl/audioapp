part of 'project_snapshot.dart';

extension LfoSnapshotWithstepvalueOperation on LfoSnapshot {
LfoSnapshot withStepValue(int index, double value) {
    final newList = List<double>.of(stepValues);
    if (index >= 0 && index < newList.length) {
      newList[index] = value.clamp(0.0, 1.0);
    }
    return copyWith(stepValues: newList);
  }
}
