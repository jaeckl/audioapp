import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

/// Tool modes for the curve editor canvas.
enum CurveEditorTool {
  /// Select & drag existing breakpoints, tap segment to highlight for shape insert.
  select,

  /// Draw/freehand — add points by dragging across canvas.
  draw,

  /// Erase — long-press or tap to remove breakpoints.
  erase,
}

/// Touch hit-test radius for breakpoint dots (generous for mobile).
const double _hitRadius = 22.0;

/// Normal (unselected) breakpoint dot radius.
const double _dotRadius = 6.0;

/// Highlighted (dragged) breakpoint dot radius.
const double _selectedDotRadius = 9.0;

/// Fullscreen curve modulator editor with toolbar, shape-insert mode, and
/// free-draw support.  All changes are flushed in a single bridge call.
class CurveEditorScreen extends StatefulWidget {
  const CurveEditorScreen({
    super.key,
    required this.mod,
    required this.onUpdate,
    required this.onBatchUpdate,
  });

  final LfoSnapshot mod;
  final Future<void> Function(String param, double value) onUpdate;
  final Future<void> Function(List<Map<String, dynamic>> params) onBatchUpdate;

  @override
  State<CurveEditorScreen> createState() => _CurveEditorScreenState();
}

class _CurveEditorScreenState extends State<CurveEditorScreen> {
  static const Color _accent = Color(0xFFE8A54B);
  static const Color _bgDark = Color(0xFF14141E);

  late List<double> _positions;
  late List<double> _values;
  late List<int> _shapes;
  int _bpCount = 0;
  int? _draggingIndex;
  CurveEditorTool _tool = CurveEditorTool.select;
  late int _polarity;

  /// When set, the segment between [segmentIdx] and [segmentIdx+1] is selected
  /// for shape insertion.  -1 = no segment selected.
  int _segmentIdx = -1;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _importMod();
  }

  @override
  void didUpdateWidget(CurveEditorScreen old) {
    super.didUpdateWidget(old);
    if (old.mod.id != widget.mod.id) _importMod();
  }

  void _importMod() {
    _positions = List<double>.from(widget.mod.curveBpPositions);
    _values = List<double>.from(widget.mod.curveBpValues);
    _shapes = List<int>.from(widget.mod.curveBpShapes);
    _bpCount = _positions.length;
    _polarity = widget.mod.polarity;
    _segmentIdx = -1;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double _valueClamp(double v) =>
      _polarity == 0 ? v.clamp(-1.0, 1.0) : v.clamp(0.0, 1.0);

  List<Map<String, dynamic>> _collectUpdates() {
    final updates = <Map<String, dynamic>>[];
    updates.add({'param': 'breakpointCount', 'value': _bpCount.toDouble()});
    updates.add({'param': 'polarity', 'value': _polarity.toDouble()});
    for (var i = 0; i < _bpCount; i++) {
      if (i < _positions.length) {
        updates.add({'param': 'bp_${i}_pos', 'value': _positions[i]});
        updates.add({'param': 'bp_${i}_val', 'value': _values[i]});
      }
      if (i < _shapes.length) {
        updates.add({'param': 'bp_${i}_shape', 'value': _shapes[i].toDouble()});
      }
    }
    return updates;
  }

  Future<void> _syncToBridge() async {
    await widget.onBatchUpdate(_collectUpdates());
  }

  void _mergeSort() {
    for (var i = 0; i < _positions.length; i++) {
      for (var j = i + 1; j < _positions.length; j++) {
        if (_positions[j] < _positions[i]) {
          double tmp = _positions[i];
          _positions[i] = _positions[j];
          _positions[j] = tmp;
          tmp = _values[i];
          _values[i] = _values[j];
          _values[j] = tmp;
          final stmp = _shapes[i];
          _shapes[i] = _shapes[j];
          _shapes[j] = stmp;
        }
      }
    }
  }

  int? _hitTestPoint(Offset localPos, Size s) {
    for (var i = 0; i < _bpCount; i++) {
      final x = _positions[i] * s.width;
      final y = s.height * (0.5 - _values[i] * 0.5);
      if ((localPos - Offset(x, y)).distance <= _hitRadius) return i;
    }
    return null;
  }

  int? _hitTestSegmentX(Offset localPos, Size s) {
    final nx = (localPos.dx / s.width).clamp(0.0, 1.0);
    for (var i = 0; i < _bpCount - 1; i++) {
      if (nx >= _positions[i] && nx <= _positions[i + 1]) return i;
    }
    return null;
  }

  double _nx(Offset localPos, Size s) =>
      (localPos.dx / s.width).clamp(0.0, 1.0);
  double _ny(Offset localPos, Size s) =>
      _valueClamp(1.0 - 2.0 * localPos.dy / s.height);

  // ---------------------------------------------------------------------------
  // Shape generation for segment insertion
  // ---------------------------------------------------------------------------

  /// Generate breakpoints for a shape between two anchors in [0..1] domain.
  /// Returns (positions, values).
  List<List<double>> _generateSegmentShape(
    String shapeName,
    double posStart,
    double posEnd,
    double valStart,
    double valEnd, {
    double floor = 0.0,
    double peak = 1.0,
    double cycles = 1.0,
    double duty = 0.5,
  }) {
    final span = posEnd - posStart;
    if (span <= 1e-6) return [<double>[], <double>[]];

    final min = floor;
    final max = peak;
    if (min > max) return _generateSegmentShape(shapeName, posStart, posEnd,
        valStart, valEnd,
        floor: peak, peak: min, cycles: cycles, duty: duty);

    List<double> pos, val;

    switch (shapeName) {
      case 'ramp':
        pos = [posStart, posEnd];
        val = [valStart, valEnd];
        return [pos, val];
      case 'saw':
        final pts = _sampleCycles((t) {
          final lin = t; // 0→1 within cycle
          return min + (max - min) * lin;
        }, span, cycles);
        pos = pts[0];
        val = pts[1];
      case 'tri':
        final pts = _sampleCycles((t) {
          final halfPhase = t < 0.5;
          final lin = halfPhase ? 2.0 * t : 2.0 - 2.0 * t;
          return min + (max - min) * lin;
        }, span, cycles);
        pos = pts[0];
        val = pts[1];
      case 'square':
        final pts = _sampleCycles((t) {
          return t < duty ? max : min;
        }, span, cycles);
        pos = pts[0];
        val = pts[1];
      case 'sine':
      default:
        final pts = _sampleCycles((t) {
          return min +
              (max - min) * (0.5 + 0.5 * math.sin(2 * math.pi * t));
        }, span, cycles);
        pos = pts[0];
        val = pts[1];
    }

    // Map back to absolute positions, replace first/last with anchors exactly.
    if (pos.isNotEmpty) {
      // Rebase: first point at posStart, last at posEnd
      for (var i = 0; i < pos.length; i++) {
        pos[i] = posStart + pos[i] * span;
      }
      pos[0] = posStart;
      pos[pos.length - 1] = posEnd;
      val[0] = valStart;
      val[val.length - 1] = valEnd;
    }
    return [pos, val];
  }

  /// Sample a function across [span] with [cycles] repetitions.
  /// Returns lists of absolute positions and values in [0,1].
  List<List<double>> _sampleCycles(
    double Function(double t) fn,
    double span,
    double cycles,
  ) {
    const stepsPerCycle = 16;
    final totalSteps = math.max(2, (stepsPerCycle * cycles).round());
    final pos = <double>[];
    final val = <double>[];
    for (var i = 0; i <= totalSteps; i++) {
      final t = i / totalSteps; // 0..1 across total cycles
      pos.add(i / totalSteps); // relative position
      val.add(fn((t * cycles) % 1.0)); // fn phase within cycle
    }
    return [pos, val];
  }

  /// Replace the segment at [_segmentIdx] with the given shape.
  void _insertShapeAtSegment(String shapeName,
      {double floor = 0.0, double peak = 1.0, double cycles = 1.0}) {
    if (_segmentIdx < 0 || _segmentIdx >= _bpCount - 1) return;

    final i = _segmentIdx;
    final p0 = _positions[i];
    final p1 = _positions[i + 1];
    final v0 = _values[i];
    final v1 = _values[i + 1];

    final pts = _generateSegmentShape(shapeName, p0, p1, v0, v1,
        floor: floor, peak: peak, cycles: cycles);

    if (pts[0].length < 2) return;

    // Remove existing interior points (i+1 is the right anchor, keep it).
    // Remove everything strictly between i and i+1.
    final removeIndices = <int>[];
    for (var j = 0; j < _bpCount; j++) {
      if (j != i && j != i + 1 &&
          _positions[j] > p0 + 1e-6 && _positions[j] < p1 - 1e-6) {
        removeIndices.add(j);
      }
    }
    // Remove in reverse order.
    removeIndices.sort((a, b) => b.compareTo(a));
    for (final idx in removeIndices) {
      _positions.removeAt(idx);
      _values.removeAt(idx);
      _shapes.removeAt(idx);
    }

    // Insert new points after index i (but not the first/last which are anchors).
    final insertPos = <double>[];
    final insertVal = <double>[];
    final insertShape = <int>[];
    for (var k = 1; k < pts[0].length - 1; k++) {
      insertPos.add(pts[0][k]);
      insertVal.add(pts[1][k]);
      insertShape.add(0); // linear segments
    }

    // Build new arrays: keep anchor i, then insert new points, then anchor i+1, then rest.
    final seq = <int>[i];
    // Find where i+1 is now (after any removals).
    final rightAnchorIdx = _positions.indexOf(p1);
    for (var k = 0; k < insertPos.length; k++) {
      seq.add(-1 - k); // sentinel for insert
    }
    seq.add(rightAnchorIdx);
    for (var j = rightAnchorIdx + 1; j < _positions.length; j++) {
      seq.add(j);
    }

    // Rebuild.
    final newPos = <double>[];
    final newVal = <double>[];
    final newShape = <int>[];
    for (final s in seq) {
      if (s >= 0) {
        newPos.add(_positions[s]);
        newVal.add(_values[s]);
        newShape.add(_shapes[s]);
      } else {
        final k = -s - 1;
        newPos.add(insertPos[k]);
        newVal.add(insertVal[k]);
        newShape.add(insertShape[k]);
      }
    }

    setState(() {
      _positions = newPos;
      _values = newVal;
      _shapes = newShape;
      _bpCount = _positions.length;
      _segmentIdx = -1; // deselect after insert
    });
    _syncToBridge();
  }

  // ---------------------------------------------------------------------------
  // Gesture handlers
  // ---------------------------------------------------------------------------

  void _onPanStart(DragStartDetails details, Size cs) {
    switch (_tool) {
      case CurveEditorTool.select:
        setState(() {
          _draggingIndex = _hitTestPoint(details.localPosition, cs);
        });
      case CurveEditorTool.draw:
        _onDrawStart(details, cs);
      case CurveEditorTool.erase:
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size cs) {
    switch (_tool) {
      case CurveEditorTool.select:
        _onSelectDrag(details, cs);
      case CurveEditorTool.draw:
        _onDrawUpdate(details, cs);
      case CurveEditorTool.erase:
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    switch (_tool) {
      case CurveEditorTool.select:
        if (_draggingIndex != null) {
          _draggingIndex = null;
          _syncToBridge();
        }
      case CurveEditorTool.draw:
        _syncToBridge();
      case CurveEditorTool.erase:
        break;
    }
  }

  void _onSelectDrag(DragUpdateDetails details, Size cs) {
    if (_draggingIndex == null) return;
    final i = _draggingIndex!;
    setState(() {
      final dp = details.delta.dx / cs.width;
      final dv = -2.0 * details.delta.dy / cs.height;
      if (i == 0) {
        _positions[i] = 0.0;
        _values[i] = _valueClamp(_values[i] + dv);
      } else if (i == _bpCount - 1) {
        _positions[i] = 1.0;
        _values[i] = _valueClamp(_values[i] + dv);
      } else {
        _positions[i] = (_positions[i] + dp).clamp(
          _positions[i - 1] + 0.01,
          _positions[i + 1] - 0.01,
        );
        _values[i] = _valueClamp(_values[i] + dv);
      }
    });
  }

  void _onDrawStart(DragStartDetails details, Size cs) {
    setState(() {
      final nx = _nx(details.localPosition, cs);
      _positions = [nx];
      _values = [_ny(details.localPosition, cs)];
      _shapes = [0];
      _segmentIdx = -1;
    });
  }

  void _onDrawUpdate(DragUpdateDetails details, Size cs) {
    final nx = _nx(details.localPosition, cs);
    if ((nx - _positions.last).abs() < 0.015) return;
    setState(() {
      _positions.add(nx);
      _values.add(_ny(details.localPosition, cs));
      _shapes.add(0);
    });
  }

  void _onTapUp(TapUpDetails details, Size cs) {
    switch (_tool) {
      case CurveEditorTool.select:
        _onSelectTap(details, cs);
      case CurveEditorTool.draw:
        _resetToDefault();
      case CurveEditorTool.erase:
        _onEraseTap(details, cs);
    }
  }

  void _onSelectTap(TapUpDetails details, Size cs) {
    final pos = details.localPosition;

    // Hit a breakpoint? → deselect segment, ignore (dragging handles move).
    if (_hitTestPoint(pos, cs) != null) {
      if (_segmentIdx >= 0) setState(() => _segmentIdx = -1);
      return;
    }

    // Hit a segment? → toggle segment selection.
    final segIdx = _hitTestSegmentX(pos, cs);
    if (segIdx != null) {
      setState(() {
        _segmentIdx = (_segmentIdx == segIdx) ? -1 : segIdx;
      });
      return;
    }

    // Otherwise → insert a new breakpoint.
    final nx = _nx(pos, cs);
    setState(() {
      _positions.add(nx);
      _values.add(_ny(pos, cs));
      _shapes.add(0);
      _mergeSort();
      _bpCount = _positions.length;
      _segmentIdx = -1;
    });
    _syncToBridge();
  }

  void _onEraseTap(TapUpDetails details, Size cs) {
    if (_bpCount <= 2) return;
    final hit = _hitTestPoint(details.localPosition, cs);
    if (hit == null) return;
    setState(() {
      _positions.removeAt(hit);
      _values.removeAt(hit);
      _shapes.removeAt(hit);
      _bpCount = _positions.length;
      _segmentIdx = -1;
    });
    _syncToBridge();
  }

  void _resetToDefault() {
    setState(() {
      _positions = [0.0, 1.0];
      _values = [0.0, 1.0];
      _shapes = [0, 0];
      _bpCount = 2;
      _segmentIdx = -1;
    });
    _syncToBridge();
  }

  /// Open shape-parameter bottom sheet and insert shape on confirm.
  void _openShapeSheet(String shapeName) {
    double floor = _polarity == 0 ? -1.0 : 0.0;
    double peak = 1.0;
    double cycles = 1.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Insert ${shapeName.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _shapeSlider(ctx, 'Floor', floor, _polarity == 0 ? -1.0 : 0.0,
                    peak - 0.01, (v) => floor = v),
                _shapeSlider(
                    ctx, 'Peak', peak, floor + 0.01, 1.0, (v) => peak = v),
                _shapeSlider(
                    ctx, 'Cycles', cycles, 0.25, 8.0, (v) => cycles = v, decimals: 1),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _insertShapeAtSegment(shapeName,
                        floor: floor, peak: peak, cycles: cycles);
                  },
                  child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _shapeSlider(
    BuildContext ctx,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    int decimals = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(ctx).copyWith(
                activeTrackColor: _accent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                thumbColor: _accent,
                overlayColor: _accent.withValues(alpha: 0.15),
                trackHeight: 3,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              value.toStringAsFixed(decimals),
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Steps stepper
  // ---------------------------------------------------------------------------

  Widget _buildStepper() {
    final canMinus = _bpCount > 2;
    final canPlus = _bpCount < 32;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('STEPS',
            style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        _stepperButton('-',
            enabled: canMinus,
            onTap: () {
              setState(() {
                _positions.removeAt(_bpCount - 1);
                _values.removeAt(_bpCount - 1);
                _shapes.removeAt(_bpCount - 1);
                _bpCount = _positions.length;
                _segmentIdx = -1;
              });
              _syncToBridge();
            }),
        const SizedBox(width: 6),
        Text('$_bpCount',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 6),
        _stepperButton('+',
            enabled: canPlus,
            onTap: () {
              setState(() {
                final last = _bpCount - 1;
                final midPos =
                    (_positions[last - 1] + _positions[last]) / 2;
                final midVal =
                    (_values[last - 1] + _values[last]) / 2;
                _positions.add(midPos.clamp(0.0, 1.0));
                _values.add(_valueClamp(midVal));
                _shapes.add(0);
                _mergeSort();
                _bpCount = _positions.length;
              });
              _syncToBridge();
            }),
      ],
    );
  }

  Widget _stepperButton(
    String label, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 32,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled
              ? _accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: enabled
                ? _accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(4),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: enabled ? _accent : Colors.white24,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Toolbar
  // ---------------------------------------------------------------------------

  Widget _buildToolbar() {
    final hasSegment = _segmentIdx >= 0 && _segmentIdx < _bpCount - 1;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          // Tool buttons
          _toolButton(Icons.pan_tool_alt_outlined, Icons.pan_tool_alt,
              CurveEditorTool.select),
          _toolButton(Icons.edit_outlined, Icons.edit, CurveEditorTool.draw),
          _toolButton(Icons.auto_fix_high_outlined, Icons.auto_fix_high,
              CurveEditorTool.erase),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.08),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Shape buttons (greyed out if no segment selected)
          _shapeBtn('Sin', 'sine', hasSegment),
          _shapeBtn('Tri', 'tri', hasSegment),
          _shapeBtn('Saw', 'saw', hasSegment),
          _shapeBtn('Sqr', 'square', hasSegment),
          _shapeBtn('Rmp', 'ramp', hasSegment),
          const Spacer(),
          // Polarity toggle
          _polarityToggle(),
          const SizedBox(width: 4),
          // Reset
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _resetToDefault,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 16, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text('Reset',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, IconData activeIcon, CurveEditorTool t) {
    final active = _tool == t;
    return Material(
      color: active ? _accent.withValues(alpha: 0.15) : Colors.transparent,
      child: InkWell(
        onTap: () =>
            setState(() { _tool = t; _segmentIdx = -1; }),
        child: SizedBox(
          width: 40,
          height: 48,
          child: Icon(
            active ? activeIcon : icon,
            size: 20,
            color: active ? _accent : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _shapeBtn(String label, String name, bool enabled) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _openShapeSheet(name) : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minWidth: 36),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          height: 28,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white60 : Colors.white.withValues(alpha: 0.15),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _polarityToggle() {
    final isBipolar = _polarity == 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _polarity = isBipolar ? 1 : 0;
            // Clamp values to new range.
            for (var i = 0; i < _values.length; i++) {
              _values[i] = _valueClamp(_values[i]);
            }
          });
          _syncToBridge();
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isBipolar
                  ? _accent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            color: isBipolar
                ? _accent.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
          ),
          alignment: Alignment.center,
          child: Text(
            isBipolar ? 'Bi' : 'Uni',
            style: TextStyle(
              color: isBipolar ? _accent : Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final hasSegment = _segmentIdx >= 0 && _segmentIdx < _bpCount - 1;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        foregroundColor: Colors.white,
        title: Text('CURVE ${widget.mod.id}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text('CURVE ${widget.mod.id}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  _buildStepper(),
                ],
              ),
            ),
            _buildToolbar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cs = Size(
                          constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapUp: (d) => _onTapUp(d, cs),
                        onPanStart: (d) => _onPanStart(d, cs),
                        onPanUpdate: (d) => _onPanUpdate(d, cs),
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: _CurveEditorPainter(
                            positions: _positions,
                            values: _values,
                            shapes: _shapes,
                            polarity: _polarity,
                            highlightedIndex: _draggingIndex,
                            segmentIdx: hasSegment ? _segmentIdx : -1,
                            accent: _accent,
                          ),
                          size: cs,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
//  _CurveEditorPainter
// =============================================================================

class _CurveEditorPainter extends CustomPainter {
  _CurveEditorPainter({
    required this.positions,
    required this.values,
    required this.shapes,
    required this.polarity,
    required this.highlightedIndex,
    required this.segmentIdx,
    required this.accent,
  });

  final List<double> positions;
  final List<double> values;
  final List<int> shapes;
  final int polarity;
  final int? highlightedIndex;
  final int segmentIdx;
  final Color accent;

  static const int _hermiteSteps = 20;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A24),
    );

    // Grid.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (polarity == 0) {
      final cy = size.height / 2;
      canvas.drawLine(
        Offset(0, cy),
        Offset(size.width, cy),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..strokeWidth = 0.5,
      );
    }

    // Highlight selected segment.
    if (segmentIdx >= 0 && segmentIdx < positions.length - 1) {
      final sx = positions[segmentIdx] * size.width;
      final ex = positions[segmentIdx + 1] * size.width;
      canvas.drawRect(
        Rect.fromLTRB(sx, 0, ex, size.height),
        Paint()..color = accent.withValues(alpha: 0.08),
      );
      canvas.drawLine(
        Offset(sx, 0),
        Offset(sx, size.height),
        Paint()
          ..color = accent.withValues(alpha: 0.3)
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        Offset(ex, 0),
        Offset(ex, size.height),
        Paint()
          ..color = accent.withValues(alpha: 0.3)
          ..strokeWidth = 1.5,
      );
    }

    final count = positions.length;
    if (count < 2) return;

    final zeroY = polarity == 0 ? size.height / 2 : size.height;
    final curvePath = Path();
    final fillPath = Path();

    double px = positions[0].clamp(0.0, 1.0) * size.width;
    double py = size.height * (0.5 - values[0].clamp(-1.0, 1.0) * 0.5);
    curvePath.moveTo(px, py);
    fillPath.moveTo(px, py);

    for (var i = 0; i < count - 1; i++) {
      final x1 = positions[i + 1].clamp(0.0, 1.0) * size.width;
      final y1 =
          size.height * (0.5 - values[i + 1].clamp(-1.0, 1.0) * 0.5);
      final shape = i < shapes.length ? shapes[i] : 0;

      switch (shape) {
        case 0:
          curvePath.lineTo(x1, y1);
          fillPath.lineTo(x1, y1);
        case 1:
          final v0 = values[i];
          final v1 = values[i + 1];
          final m = (v1 - v0) * 0.5;
          final segWidth = x1 - px;
          for (var s = 1; s <= _hermiteSteps; s++) {
            final t = s / _hermiteSteps;
            final t2 = t * t;
            final t3 = t2 * t;
            final v = 2 * t3 * v0 -
                3 * t2 * v0 +
                v0 +
                t3 * m -
                2 * t2 * m +
                t * m +
                -2 * t3 * v1 +
                3 * t2 * v1 +
                t3 * m -
                t2 * m;
            final ix = px + segWidth * t;
            final iy = size.height * (0.5 - v * 0.5);
            curvePath.lineTo(ix, iy);
            fillPath.lineTo(ix, iy);
          }
        case 2:
          curvePath.lineTo(x1, py);
          curvePath.lineTo(x1, y1);
          fillPath.lineTo(x1, py);
          fillPath.lineTo(x1, y1);
      }
      px = x1;
      py = y1;
    }

    final lastX = positions[count - 1].clamp(0.0, 1.0) * size.width;
    final firstX = positions[0].clamp(0.0, 1.0) * size.width;
    fillPath.lineTo(lastX, zeroY);
    fillPath.lineTo(firstX, zeroY);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      curvePath,
      Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < count; i++) {
      final x = positions[i].clamp(0.0, 1.0) * size.width;
      final y = size.height * (0.5 - values[i].clamp(-1.0, 1.0) * 0.5);
      final isHighlighted = highlightedIndex == i;
      final r = isHighlighted ? _selectedDotRadius : _dotRadius;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = isHighlighted
              ? accent
              : accent.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill,
      );
      if (isHighlighted) {
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    for (var i = 0; i < count - 1; i++) {
      final shape = i < shapes.length ? shapes[i] : 0;
      final label = ['L', 'S', 'H'][shape.clamp(0, 2)];
      final mx = (positions[i] + positions[i + 1]) / 2 * size.width;
      final midV = (values[i] + values[i + 1]) / 2;
      final my = size.height * (0.5 - midV * 0.5);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(mx - tp.width / 2, my - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_CurveEditorPainter old) {
    if (old.positions.length != positions.length) return true;
    for (var i = 0; i < positions.length; i++) {
      if (old.positions[i] != positions[i] ||
          old.values[i] != values[i] ||
          old.shapes[i] != shapes[i]) return true;
    }
    return old.polarity != polarity ||
        old.highlightedIndex != highlightedIndex ||
        old.segmentIdx != segmentIdx ||
        old.accent != accent;
  }
}