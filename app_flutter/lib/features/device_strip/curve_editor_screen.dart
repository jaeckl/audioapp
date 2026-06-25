import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';

/// Tool modes for the curve editor canvas.
enum CurveEditorTool {
  /// Select & drag existing breakpoints.
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

/// Fullscreen curve modulator editor with toolbar, waveform presets, and
/// free-draw support.  All changes are flushed to the engine in a single
/// [batchUpdateLfoParams] call.
class CurveEditorScreen extends StatefulWidget {
  const CurveEditorScreen({
    super.key,
    required this.mod,
    required this.onUpdate,
    required this.onBatchUpdate,
  });

  /// The [LfoSnapshot] for the curve modulator being edited.
  final LfoSnapshot mod;

  /// Single-param bridge callback (kept for compatibility with properties panel).
  final Future<void> Function(String param, double value) onUpdate;

  /// Batch bridge callback — receives a list of {param, value} maps.
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
    if (old.mod.id != widget.mod.id) {
      _importMod();
    }
  }

  void _importMod() {
    _positions = List<double>.from(widget.mod.curveBpPositions);
    _values = List<double>.from(widget.mod.curveBpValues);
    _shapes = List<int>.from(widget.mod.curveBpShapes);
    _bpCount = _positions.length;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int get _polarity => widget.mod.polarity;

  double _valueClamp(double v) {
    return _polarity == 0 ? v.clamp(-1.0, 1.0) : v.clamp(0.0, 1.0);
  }

  /// Collect all param updates into a list for a single batch bridge call.
  List<Map<String, dynamic>> _collectUpdates() {
    final updates = <Map<String, dynamic>>[];
    updates.add({'param': 'breakpointCount', 'value': _bpCount.toDouble()});
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

  /// Flush all current breakpoint state to the engine in a single call.
  Future<void> _syncToBridge() async {
    await widget.onBatchUpdate(_collectUpdates());
  }

  /// Bubble-sort all three arrays by position.
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

  /// Return the breakpoint index whose canvas position is within [_hitRadius]
  /// of [localPos], or null.
  int? _hitTestPoint(Offset localPos, Size s) {
    for (var i = 0; i < _bpCount; i++) {
      final x = _positions[i] * s.width;
      final y = s.height * (0.5 - _values[i] * 0.5);
      if ((localPos - Offset(x, y)).distance <= _hitRadius) return i;
    }
    return null;
  }

  /// Return segment index whose X-range contains the normalized X, or null.
  int? _hitTestSegmentX(Offset localPos, Size s) {
    final nx = (localPos.dx / s.width).clamp(0.0, 1.0);
    for (var i = 0; i < _bpCount - 1; i++) {
      if (nx >= _positions[i] && nx <= _positions[i + 1]) return i;
    }
    return null;
  }

  /// Normalised canvas X/Y from a local position.
  double _nx(Offset localPos, Size s) =>
      (localPos.dx / s.width).clamp(0.0, 1.0);
  double _ny(Offset localPos, Size s) =>
      _valueClamp(0.5 - localPos.dy / s.height * 0.5 * 2.0);

  // ---------------------------------------------------------------------------
  // Waveform presets
  // ---------------------------------------------------------------------------

  /// Generate breakpoints approximating a standard waveform.
  /// Returns (positions, values) lists.
  List<List<double>> _waveformPoints(String name) {
    switch (name) {
      case 'sine':
        return _sampleCurve((t) => math.sin(t * 2 * math.pi));
      case 'tri':
        return _sampleCurve((t) {
          if (t < 0.25) return 4.0 * t;
          if (t < 0.75) return 2.0 - 4.0 * t;
          return 4.0 * t - 4.0;
        });
      case 'saw':
        return _sampleCurve((t) => 2.0 * t - 1.0);
      case 'square':
        return _sampleCurve((t) => t < 0.5 ? 1.0 : -1.0);
      case 'ramp':
        return _sampleCurve((t) => 1.0 - 2.0 * t);
      default:
        return [
          [0.0, 1.0],
          [0.0, 1.0]
        ];
    }
  }

  /// Sample a function at 16 equidistant points and return [positions, values].
  List<List<double>> _sampleCurve(double Function(double) fn) {
    const n = 16;
    final pos = <double>[];
    final val = <double>[];
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      pos.add(t);
      val.add(fn(t));
    }
    return [pos, val];
  }

  void _applyWaveform(String name) {
    final pts = _waveformPoints(name);
    setState(() {
      _positions = pts[0];
      _values = pts[1];
      _shapes = List.filled(_positions.length, 0);
      _bpCount = _positions.length;
    });
    _syncToBridge();
  }

  // ---------------------------------------------------------------------------
  // Gesture handlers (delegated by tool)
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

  // --- Select mode: drag breakpoints ---

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

  // --- Draw mode: freehand curve drawing ---

  void _onDrawStart(DragStartDetails details, Size cs) {
    setState(() {
      final nx = _nx(details.localPosition, cs);
      final ny = _ny(details.localPosition, cs);
      _positions = [nx];
      _values = [ny];
      _shapes = [0];
    });
  }

  void _onDrawUpdate(DragUpdateDetails details, Size cs) {
    final nx = _nx(details.localPosition, cs);
    final ny = _ny(details.localPosition, cs);
    // Only add if we've moved far enough (avoids noise).
    if ((nx - _positions.last).abs() < 0.015) return;
    setState(() {
      _positions.add(nx);
      _values.add(ny);
      _shapes.add(0);
    });
  }

  // --- Tap (select, draw-finish, erase) ---

  void _onTapUp(TapUpDetails details, Size cs) {
    switch (_tool) {
      case CurveEditorTool.select:
        _onSelectTap(details, cs);
      case CurveEditorTool.draw:
        // In draw mode, tapping clears the curve.
        _resetToDefault();
      case CurveEditorTool.erase:
        _onEraseTap(details, cs);
    }
  }

  void _onSelectTap(TapUpDetails details, Size cs) {
    final pos = details.localPosition;

    // Inside a dot radius → ignore (dragging handles movement).
    if (_hitTestPoint(pos, cs) != null) return;

    // Inside a segment → cycle shape (linear→smooth→step→linear).
    final segIdx = _hitTestSegmentX(pos, cs);
    if (segIdx != null) {
      setState(() {
        _shapes[segIdx] = (_shapes[segIdx] + 1) % 3;
      });
      _syncToBridge();
      return;
    }

    // Otherwise → insert a new breakpoint at tap position.
    final nx = _nx(pos, cs);
    setState(() {
      _positions.add(nx);
      _values.add(_ny(pos, cs));
      _shapes.add(0);
      _mergeSort();
      _bpCount = _positions.length;
    });
    _syncToBridge();
  }

  // --- Erase mode ---

  void _onEraseTap(TapUpDetails details, Size cs) {
    if (_bpCount <= 2) return;
    final hit = _hitTestPoint(details.localPosition, cs);
    if (hit == null) return;
    setState(() {
      _positions.removeAt(hit);
      _values.removeAt(hit);
      _shapes.removeAt(hit);
      _bpCount = _positions.length;
    });
    _syncToBridge();
  }

  /// Reset to a simple 2-breakpoint linear ramp.
  void _resetToDefault() {
    setState(() {
      _positions = [0.0, 1.0];
      _values = [0.0, 1.0];
      _shapes = [0, 0];
      _bpCount = 2;
    });
    _syncToBridge();
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
        const Text(
          'STEPS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        _stepperButton(
          '-',
          enabled: canMinus,
          onTap: () {
            setState(() {
              _positions.removeAt(_bpCount - 1);
              _values.removeAt(_bpCount - 1);
              _shapes.removeAt(_bpCount - 1);
              _bpCount = _positions.length;
            });
            _syncToBridge();
          },
        ),
        const SizedBox(width: 6),
        Text(
          '$_bpCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 6),
        _stepperButton(
          '+',
          enabled: canPlus,
          onTap: () {
            setState(() {
              final last = _bpCount - 1;
              final midPos = (_positions[last - 1] + _positions[last]) / 2;
              final midVal = (_values[last - 1] + _values[last]) / 2;
              _positions.add(midPos.clamp(0.0, 1.0));
              _values.add(_valueClamp(midVal));
              _shapes.add(0);
              _mergeSort();
              _bpCount = _positions.length;
            });
            _syncToBridge();
          },
        ),
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
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? _accent : Colors.white24,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          _toolButton(
              Icons.auto_fix_high_outlined, Icons.auto_fix_high, CurveEditorTool.erase),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.08),
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Waveform presets
          _presetButton('Sin', 'sine'),
          _presetButton('Tri', 'tri'),
          _presetButton('Saw', 'saw'),
          _presetButton('Sqr', 'square'),
          _presetButton('Rmp', 'ramp'),
          const Spacer(),
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
                    Text(
                      'Reset',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
        onTap: () => setState(() => _tool = t),
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

  Widget _presetButton(String label, String name) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _applyWaveform(name),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minWidth: 36),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          height: 28,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.w600,
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
        title: Text(
          'CURVE ${widget.mod.id}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: Column(
          children: [
            // Header row: curve label + steps stepper
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    'CURVE ${widget.mod.id}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _buildStepper(),
                ],
              ),
            ),
            // Toolbar
            _buildToolbar(),
            // Full-height curve editing canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cs = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
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
    required this.accent,
  });

  final List<double> positions;
  final List<double> values;
  final List<int> shapes;
  final int polarity;
  final int? highlightedIndex;
  final Color accent;

  /// Number of linear subdivisions per smooth (Hermite) segment.
  static const int _hermiteSteps = 20;

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A24),
    );

    // Horizontal grid lines (5 rows).
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Center line (bipolar only).
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

    final count = positions.length;
    if (count < 2) return;

    final zeroY = polarity == 0 ? size.height / 2 : size.height;
    final curvePath = Path();
    final fillPath = Path();

    // First point.
    double px = positions[0].clamp(0.0, 1.0) * size.width;
    double py = size.height * (0.5 - values[0].clamp(-1.0, 1.0) * 0.5);
    curvePath.moveTo(px, py);
    fillPath.moveTo(px, py);

    // Build paths segment by segment.
    for (var i = 0; i < count - 1; i++) {
      final x1 = positions[i + 1].clamp(0.0, 1.0) * size.width;
      final y1 =
          size.height * (0.5 - values[i + 1].clamp(-1.0, 1.0) * 0.5);
      final shape = i < shapes.length ? shapes[i] : 0;

      switch (shape) {
        case 0: // Linear
          curvePath.lineTo(x1, y1);
          fillPath.lineTo(x1, y1);
        case 1: // Smooth (cubic Hermite)
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
        case 2: // Step
          curvePath.lineTo(x1, py);
          curvePath.lineTo(x1, y1);
          fillPath.lineTo(x1, py);
          fillPath.lineTo(x1, y1);
      }

      px = x1;
      py = y1;
    }

    // Close fill path to zero line.
    final lastX = positions[count - 1].clamp(0.0, 1.0) * size.width;
    final firstX = positions[0].clamp(0.0, 1.0) * size.width;
    fillPath.lineTo(lastX, zeroY);
    fillPath.lineTo(firstX, zeroY);
    fillPath.close();

    // Fill below curve.
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );

    // Curve line.
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Breakpoint dots.
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

    // Shape indicators (L / S / H) near segment midpoints.
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
      if (old.positions[i] != positions[i]) return true;
      if (old.values[i] != values[i]) return true;
      if (old.shapes[i] != shapes[i]) return true;
    }
    return old.polarity != polarity ||
        old.highlightedIndex != highlightedIndex ||
        old.accent != accent;
  }
}