import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

/// Tool modes for the curve editor canvas.
enum CurveEditorTool {
  /// Select & drag existing breakpoints. Tap to select (max 2).
  /// With 2 selected, shape-insert button becomes active.
  select,

  /// Freehand draw — drag across canvas to replace breakpoints in the drawn X-range.
  draw,

  /// Tap a breakpoint to delete it. Endpoints cannot be deleted.
  erase,
}

const double _hitRadius = 22.0;
const double _dotRadius = 6.0;
const double _selectedDotRadius = 9.0;

/// Fullscreen curve modulator editor with automation-style tool system.
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

  /// Selected point indices (max 2) for shape insertion.
  final Set<int> _selectedIndices = {};

  int get _lastIdx => _bpCount - 1;

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
    _selectedIndices.clear();
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

  double _nx(Offset localPos, Size s) =>
      (localPos.dx / s.width).clamp(0.0, 1.0);
  double _ny(Offset localPos, Size s) =>
      _valueClamp(1.0 - 2.0 * localPos.dy / s.height);

  // ---------------------------------------------------------------------------
  // Point selection
  // ---------------------------------------------------------------------------

  void _toggleSelect(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else if (_selectedIndices.length >= 2) {
        final oldest = _selectedIndices.toList()..sort();
        _selectedIndices.remove(oldest.first);
        _selectedIndices.add(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIndices.clear());
  }

  // ---------------------------------------------------------------------------
  // Shape generation between two anchor points
  // ---------------------------------------------------------------------------

  /// Generate breakpoints for [shapeName] between [posStart]..[posEnd],
  /// producing linear breakpoints that approximate the waveform with
  /// [cycles] repetitions. Anchor positions/values are preserved exactly.
  List<List<double>> _generateSegmentShape(
    String shapeName,
    double posStart,
    double posEnd,
    double valStart,
    double valEnd, {
    required double floor,
    required double peak,
    required double cycles,
  }) {
    final span = posEnd - posStart;
    if (span <= 1e-6) return [<double>[], <double>[]];

    final lo = math.min(floor, peak);
    final hi = math.max(floor, peak);

    const stepsPerCycle = 16;
    final total = math.max(2, (stepsPerCycle * cycles).round());

    final pos = <double>[];
    final val = <double>[];

    for (var i = 0; i <= total; i++) {
      final t = i / total;
      final phase = (t * cycles) % 1.0;
      double v;
      switch (shapeName) {
        case 'ramp':
          v = lo + (hi - lo) * phase;
        case 'saw':
          v = lo + (hi - lo) * phase;
        case 'tri':
          v = phase < 0.5 ? lo + (hi - lo) * 2.0 * phase : lo + (hi - lo) * (2.0 - 2.0 * phase);
        case 'square':
          v = phase < 0.5 ? hi : lo;
        case 'sine':
        default:
          v = lo + (hi - lo) * (0.5 + 0.5 * math.sin(2 * math.pi * phase));
      }
      pos.add(posStart + t * span);
      val.add(v);
    }

    // Force anchor values exactly.
    pos[0] = posStart;
    val[0] = valStart;
    pos[pos.length - 1] = posEnd;
    val[val.length - 1] = valEnd;

    return [pos, val];
  }

  /// Replace all breakpoints strictly between two anchor points with a
  /// shaped curve, then sync to bridge.
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

    final pts = _generateSegmentShape(shapeName, posStart, posEnd,
        valStart, valEnd,
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
      _bpCount = _positions.length;
      _selectedIndices.clear();
    });
    _syncToBridge();
  }

  /// Open bottom sheet to pick shape type and parameters, then insert.
  void _openShapeSheet() {
    if (_selectedIndices.length != 2) return;

    final sorted = _selectedIndices
        .map((i) => (idx: i, pos: _positions[i], val: _values[i]))
        .toList()
      ..sort((a, b) => a.pos.compareTo(b.pos));

    final startPos = sorted[0].pos;
    final endPos = sorted[1].pos;
    final startVal = sorted[0].val;
    final endVal = sorted[1].val;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        return _ShapeInsertSheet(
          accent: _accent,
          polarity: _polarity,
          startVal: startVal,
          endVal: endVal,
          onApply: (shapeName, floor, peak, cycles) {
            _insertShapeBetween(shapeName, startPos, endPos, startVal, endVal,
                floor: floor, peak: peak, cycles: cycles);
          },
        );
      },
    );
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
        _onDrawEnd();
      case CurveEditorTool.erase:
        break;
    }
  }

  // --- Select ---

  void _onSelectDrag(DragUpdateDetails details, Size cs) {
    if (_draggingIndex == null) return;
    final i = _draggingIndex!;
    setState(() {
      final dv = -2.0 * details.delta.dy / cs.height;
      if (i == 0) {
        _positions[i] = 0.0;
        _values[i] = _valueClamp(_values[i] + dv);
      } else if (i == _lastIdx) {
        _positions[i] = 1.0;
        _values[i] = _valueClamp(_values[i] + dv);
      } else {
        final dp = details.delta.dx / cs.width;
        _positions[i] = (_positions[i] + dp).clamp(
          _positions[i - 1] + 0.01,
          _positions[i + 1] - 0.01,
        );
        _values[i] = _valueClamp(_values[i] + dv);
      }
    });
  }

  void _onSelectTap(TapUpDetails details, Size cs) {
    final hit = _hitTestPoint(details.localPosition, cs);
    if (hit != null) {
      _toggleSelect(hit);
    } else {
      _clearSelection();
    }
  }

  // --- Draw ---

  /// Points accumulated during the current draw gesture.
  final List<double> _drawAccPos = [];
  final List<double> _drawAccVal = [];

  void _onDrawStart(DragStartDetails details, Size cs) {
    final nx = _nx(details.localPosition, cs);
    _drawAccPos.clear();
    _drawAccVal.clear();
    _drawAccPos.add(nx);
    _drawAccVal.add(_ny(details.localPosition, cs));
    setState(() => _selectedIndices.clear());
  }

  void _onDrawUpdate(DragUpdateDetails details, Size cs) {
    final nx = _nx(details.localPosition, cs);
    if ((nx - _drawAccPos.last).abs() < 0.015) return;
    _drawAccPos.add(nx);
    _drawAccVal.add(_ny(details.localPosition, cs));
    setState(() => _rebuildFromDraw());
  }

  void _onDrawEnd() {
    _rebuildFromDraw();
    _drawAccPos.clear();
    _drawAccVal.clear();
    _syncToBridge();
  }

  /// Rebuild breakpoints keeping everything outside the draw X range and
  /// replacing everything inside with the accumulated draw points.
  void _rebuildFromDraw() {
    if (_drawAccPos.isEmpty) return;
    final drawMin = _drawAccPos.reduce(math.min);
    final drawMax = _drawAccPos.reduce(math.max);

    final newPos = <double>[];
    final newVal = <double>[];
    final newShape = <int>[];

    // Points before draw range (including left endpoint).
    for (var i = 0; i < _bpCount; i++) {
      if (_positions[i] < drawMin - 1e-6 || i == 0) {
        newPos.add(_positions[i]);
        newVal.add(_values[i]);
        newShape.add(_shapes[i]);
      }
    }

    // Drawn points.
    for (var i = 0; i < _drawAccPos.length; i++) {
      newPos.add(_drawAccPos[i]);
      newVal.add(_drawAccVal[i]);
      newShape.add(0);
    }

    // Points after draw range (including right endpoint).
    for (var i = 0; i < _bpCount; i++) {
      if (_positions[i] > drawMax + 1e-6 || i == _lastIdx) {
        newPos.add(_positions[i]);
        newVal.add(_values[i]);
        newShape.add(_shapes[i]);
      }
    }

    _positions = newPos;
    _values = newVal;
    _shapes = newShape;
    _mergeSort();
    _bpCount = _positions.length;
  }

  // --- Tap dispatch ---

  void _onTapUp(TapUpDetails details, Size cs) {
    switch (_tool) {
      case CurveEditorTool.select:
        _onSelectTap(details, cs);
      case CurveEditorTool.draw:
        break; // tap in draw mode does nothing
      case CurveEditorTool.erase:
        _onEraseTap(details, cs);
    }
  }

  // --- Erase ---

  void _onEraseTap(TapUpDetails details, Size cs) {
    if (_bpCount <= 2) return;
    final hit = _hitTestPoint(details.localPosition, cs);
    if (hit == null || hit == 0 || hit == _lastIdx) return;
    setState(() {
      _positions.removeAt(hit);
      _values.removeAt(hit);
      _shapes.removeAt(hit);
      _bpCount = _positions.length;
      _selectedIndices.clear();
    });
    _syncToBridge();
  }

  void _resetToDefault() {
    setState(() {
      _positions = [0.0, 1.0];
      _values = [_polarity == 0 ? 0.0 : 0.5, _polarity == 0 ? 1.0 : 0.5];
      _shapes = [0, 0];
      _bpCount = 2;
      _selectedIndices.clear();
    });
    _syncToBridge();
  }

  // ---------------------------------------------------------------------------
  // Toolbar
  // ---------------------------------------------------------------------------

  Widget _buildToolbar() {
    final canInsert = _selectedIndices.length == 2;
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
          _toolBtn(Icons.pan_tool_alt_outlined, Icons.pan_tool_alt,
              CurveEditorTool.select),
          _toolBtn(Icons.edit_outlined, Icons.edit, CurveEditorTool.draw),
          _toolBtn(Icons.auto_fix_high_outlined, Icons.auto_fix_high,
              CurveEditorTool.erase),
          const SizedBox(width: 4),
          // Separator
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 4),
          // Insert shape button (waves icon, active when 2 selected)
          _iconBtn(
            canInsert ? Icons.waves : Icons.waves_outlined,
            canInsert,
            canInsert ? _openShapeSheet : null,
          ),
          const Spacer(),
          _polarityToggle(),
          const SizedBox(width: 4),
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
                        style: const TextStyle(
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

  Widget _toolBtn(IconData icon, IconData activeIcon, CurveEditorTool t) {
    final active = _tool == t;
    return Material(
      color: active ? _accent.withValues(alpha: 0.15) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _tool = t;
          _selectedIndices.clear();
        }),
        child: SizedBox(
          width: 40,
          height: 48,
          child: Icon(active ? activeIcon : icon,
              size: 20, color: active ? _accent : Colors.white54),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, bool enabled, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 48,
          child: Icon(icon,
              size: 20,
              color: enabled
                  ? _accent
                  : Colors.white.withValues(alpha: 0.2)),
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
      body: Column(
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
                Text('${_bpCount} pts',
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
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
                    final cs =
                        Size(constraints.maxWidth, constraints.maxHeight);
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
                          selectedIndices: _selectedIndices,
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
    );
  }
}

// =============================================================================
//  Shape insert bottom sheet
// =============================================================================

class _ShapeInsertSheet extends StatefulWidget {
  const _ShapeInsertSheet({
    required this.accent,
    required this.polarity,
    required this.startVal,
    required this.endVal,
    required this.onApply,
  });

  final Color accent;
  final int polarity;
  final double startVal;
  final double endVal;
  final void Function(String shapeName, double floor, double peak, double cycles)
      onApply;

  @override
  State<_ShapeInsertSheet> createState() => _ShapeInsertSheetState();
}

class _ShapeInsertSheetState extends State<_ShapeInsertSheet> {
  String _selectedShape = 'sine';
  late double _floor;
  late double _peak;
  double _cycles = 1.0;

  @override
  void initState() {
    super.initState();
    _floor = math.min(widget.startVal, widget.endVal);
    _peak = math.max(widget.startVal, widget.endVal);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Insert shape',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Sin', 'sine'),
                _chip('Tri', 'tri'),
                _chip('Saw', 'saw'),
                _chip('Sqr', 'square'),
                _chip('Rmp', 'ramp'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _slider('Floor', _floor,
              widget.polarity == 0 ? -1.0 : 0.0, _peak - 0.01, (v) {
            setState(() => _floor = v);
          }),
          _slider('Peak', _peak, _floor + 0.01, 1.0, (v) {
            setState(() => _peak = v);
          }),
          _slider('Cycles', _cycles, 0.25, 8.0, (v) {
            setState(() => _cycles = v);
          }, decimals: 1),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              widget.onApply(_selectedShape, _floor, _peak, _cycles);
              Navigator.of(context).pop();
            },
            child: const Text('Apply',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String name) {
    final selected = _selectedShape == name;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected
            ? widget.accent.withValues(alpha: 0.22)
            : const Color(0xFF2A2A36),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedShape = name),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? widget.accent
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    color: selected ? widget.accent : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged,
      {int decimals = 2}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white60, fontSize: 11)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: widget.accent,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                thumbColor: widget.accent,
                overlayColor: widget.accent.withValues(alpha: 0.15),
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
    required this.selectedIndices,
    required this.accent,
  });

  final List<double> positions;
  final List<double> values;
  final List<int> shapes;
  final int polarity;
  final int? highlightedIndex;
  final Set<int> selectedIndices;
  final Color accent;

  static const int _hermiteSteps = 20;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A24),
    );

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

    // Highlight region between two selected points.
    if (selectedIndices.length == 2) {
      final sorted = selectedIndices.toList()
        ..sort((a, b) => positions[a].compareTo(positions[b]));
      final sx = positions[sorted[0]] * size.width;
      final ex = positions[sorted[1]] * size.width;
      canvas.drawRect(
        Rect.fromLTRB(sx, 0, ex, size.height),
        Paint()..color = accent.withValues(alpha: 0.08),
      );
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height),
          Paint()..color = accent.withValues(alpha: 0.3)..strokeWidth = 1.5);
      canvas.drawLine(Offset(ex, 0), Offset(ex, size.height),
          Paint()..color = accent.withValues(alpha: 0.3)..strokeWidth = 1.5);
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
      final y1 = size.height * (0.5 - values[i + 1].clamp(-1.0, 1.0) * 0.5);
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
            final v = 2 * t3 * v0 - 3 * t2 * v0 + v0 + t3 * m - 2 * t2 * m +
                t * m + -2 * t3 * v1 + 3 * t2 * v1 + t3 * m - t2 * m;
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

    canvas.drawPath(fillPath,
        Paint()..color = accent.withValues(alpha: 0.12)..style = PaintingStyle.fill);
    canvas.drawPath(curvePath,
        Paint()..color = accent.withValues(alpha: 0.9)..strokeWidth = 2.0
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    for (var i = 0; i < count; i++) {
      final x = positions[i].clamp(0.0, 1.0) * size.width;
      final y = size.height * (0.5 - values[i].clamp(-1.0, 1.0) * 0.5);
      final isSel = selectedIndices.contains(i);
      final isDrag = highlightedIndex == i;
      final r = (isSel || isDrag) ? _selectedDotRadius : _dotRadius;
      final dotColor = (isSel || isDrag) ? accent : accent.withValues(alpha: 0.7);
      canvas.drawCircle(Offset(x, y), r,
          Paint()..color = dotColor..style = PaintingStyle.fill);
      if (isSel || isDrag) {
        canvas.drawCircle(Offset(x, y), r,
            Paint()..color = Colors.white.withValues(alpha: 0.3)
              ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    for (var i = 0; i < count - 1; i++) {
      final s = i < shapes.length ? shapes[i] : 0;
      final label = ['L', 'S', 'H'][s.clamp(0, 2)];
      final mx = (positions[i] + positions[i + 1]) / 2 * size.width;
      final midV = (values[i] + values[i + 1]) / 2;
      final my = size.height * (0.5 - midV * 0.5);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 9,
              fontWeight: FontWeight.w600),
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
        old.selectedIndices.length != selectedIndices.length ||
        !old.selectedIndices.every(selectedIndices.contains) ||
        old.accent != accent;
  }
}