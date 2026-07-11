part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateCollectupdates on _CurveEditorScreenState {
  List<Map<String, dynamic>> _collectUpdates() {
    const int maxEngineBp = 64;

    // Always work against the actual current length to avoid stale _bpCount.
    final bpCount = _positions.length;
    if (bpCount < 2) {
      return [
        {'param': 'breakpointCount', 'value': 2.0},
        {'param': 'polarity', 'value': _polarity.toDouble()},
        {'param': 'bp_0_pos', 'value': 0.0},
        {'param': 'bp_0_val', 'value': _polarity == 0 ? 0.0 : 0.5},
        {'param': 'bp_0_shape', 'value': 0.0},
        {'param': 'bp_1_pos', 'value': 1.0},
        {'param': 'bp_1_val', 'value': _polarity == 0 ? 1.0 : 0.5},
        {'param': 'bp_1_shape', 'value': 0.0},
      ];
    }

    // Decimate breakpoints to avoid exceeding the engine array size (64).
    int decimateStep = 1;
    if (bpCount > maxEngineBp) {
      decimateStep = (bpCount / maxEngineBp).ceil();
    }

    // Build decimated index list.
    final indices = <int>[];
    for (var i = 0; i < bpCount; i += decimateStep) {
      indices.add(i);
    }
    // Ensure the very last point is included.
    if (indices.last != bpCount - 1) indices.add(bpCount - 1);

    // Sort decimated indices by position so the engine receives
    // breakpoints in strictly ascending X-order. Values and shapes
    // are read through the same indices, keeping the parallel arrays
    // consistent.
    indices.sort((a, b) => _positions[a].compareTo(_positions[b]));

    final updates = <Map<String, dynamic>>[];
    updates
        .add({'param': 'breakpointCount', 'value': indices.length.toDouble()});
    updates.add({'param': 'polarity', 'value': _polarity.toDouble()});
    for (var i = 0; i < indices.length; i++) {
      final src = indices[i];
      updates.add({'param': 'bp_${i}_pos', 'value': _positions[src]});
      updates.add({'param': 'bp_${i}_val', 'value': _values[src]});
      updates.add({'param': 'bp_${i}_shape', 'value': _shapes[src].toDouble()});
    }
    return updates;
  }
}
