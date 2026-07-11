part of 'curve_editor_screen.dart';

extension _CurveEditorScreenStateInsertshapebetween on _CurveEditorScreenState {
  void _insertShapeBetween(
    String shapeName,
    double posStart,
    double posEnd,
    double valStart,
    double valEnd, {
    required double floor,
    required double peak,
    required double cycles,
  }) {
    if (posEnd - posStart <= 1e-6) return;

    final pts = _generateSegmentShape(
        shapeName, posStart, posEnd, valStart, valEnd,
        floor: floor, peak: peak, cycles: cycles);
    if (pts[0].length < 2) return;

    // Remove interior points between the two anchors.
    final toRemove = <int>[];
    for (var i = 1; i < _bpCount - 1; i++) {
      if (_positions[i] > posStart + 1e-6 && _positions[i] < posEnd - 1e-6) {
        toRemove.add(i);
      }
    }
    for (final idx in toRemove.reversed) {
      _positions.removeAt(idx);
      _values.removeAt(idx);
      _shapes.removeAt(idx);
    }

    // Find the index of the right anchor after removals.
    final rightIdx = _positions.indexOf(posEnd);
    if (rightIdx < 0) return;

    // Insert new points before rightIdx (skip first/last which are anchors).
    final newPos = <double>[_positions[0]];
    final newVal = <double>[_values[0]];
    final newShape = <int>[_shapes[0]];

    // Copy points from index 1..rightIdx-1 (interior before the anchor).
    for (var i = 1; i < rightIdx; i++) {
      newPos.add(_positions[i]);
      newVal.add(_values[i]);
      newShape.add(_shapes[i]);
    }

    // Insert generated shape interior points (skip first/last = anchors).
    for (var k = 1; k < pts[0].length - 1; k++) {
      newPos.add(pts[0][k]);
      newVal.add(pts[1][k]);
      newShape.add(0);
    }

    // Copy from rightIdx onward.
    for (var i = rightIdx; i < _positions.length; i++) {
      newPos.add(_positions[i]);
      newVal.add(_values[i]);
      newShape.add(_shapes[i]);
    }

    setState(() {
      _positions = newPos;
      _values = newVal;
      _shapes = newShape;
      _mergeSort();
      _bpCount = _positions.length;
      _selectedIndices.clear();
    });
    _syncToBridge();
  }
}
