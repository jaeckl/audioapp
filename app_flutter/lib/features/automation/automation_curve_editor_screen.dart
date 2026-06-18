import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'automation_curve_shapes.dart';

/// Full-screen editor for automation clip breakpoints.
class AutomationCurveEditorScreen extends StatefulWidget {
  const AutomationCurveEditorScreen({
    super.key,
    required this.trackName,
    required this.clip,
    required this.bridge,
    required this.onSaved,
  });

  final String trackName;
  final AutomationClipSnapshot clip;
  final EngineBridge bridge;
  final ValueChanged<ProjectSnapshot> onSaved;

  @override
  State<AutomationCurveEditorScreen> createState() =>
      _AutomationCurveEditorScreenState();
}

class _AutomationCurveEditorScreenState extends State<AutomationCurveEditorScreen> {
  late List<AutomationPointSnapshot> _points;
  int? _dragIndex;
  bool _saving = false;
  AutomationCurveShape? _activeShape;
  AutomationShapeParams _shapeParams = const AutomationShapeParams();

  @override
  void initState() {
    super.initState();
    _points = List.of(widget.clip.points);
    if (_points.length < 2) {
      _points = [
        const AutomationPointSnapshot(beat: 0, value: 1),
        AutomationPointSnapshot(beat: widget.clip.lengthBeats, value: 0.25),
      ];
    }
    _shapeParams = _shapeParamsFromPoints(_points);
  }

  AutomationShapeParams _shapeParamsFromPoints(List<AutomationPointSnapshot> points) {
    if (points.isEmpty) return const AutomationShapeParams();
    var min = points.first.value;
    var max = points.first.value;
    for (final p in points) {
      min = math.min(min, p.value);
      max = math.max(max, p.value);
    }
    return AutomationShapeParams(min: min, max: max);
  }

  void _applyActiveShape() {
    final shape = _activeShape;
    if (shape == null) return;
    _points = generateAutomationShapePoints(
      shape: shape,
      params: _shapeParams,
      lengthBeats: widget.clip.lengthBeats,
    );
  }

  void _selectShape(AutomationCurveShape shape) {
    setState(() {
      _activeShape = shape;
      _applyActiveShape();
    });
    HapticFeedback.selectionClick();
  }

  void _setShapeParams(AutomationShapeParams params) {
    setState(() {
      _shapeParams = params;
      if (_activeShape != null) {
        _applyActiveShape();
      }
    });
  }

  void _clearActiveShape() {
    _activeShape = null;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final sorted = List<AutomationPointSnapshot>.of(_points)
        ..sort((a, b) => a.beat.compareTo(b.beat));
      final snapshot = await widget.bridge.setAutomationPoints(
        clipId: widget.clip.id,
        points: sorted,
      );
      widget.onSaved(snapshot);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save automation: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updatePoint(int index, {double? beat, double? value}) {
    _clearActiveShape();
    setState(() {
      final current = _points[index];
      _points[index] = AutomationPointSnapshot(
        beat: beat ?? current.beat,
        value: value ?? current.value,
      );
    });
  }

  int? _hitTestPoint(Offset local, Size size) {
    const hitRadius = 18.0;
    for (var i = 0; i < _points.length; i++) {
      final p = _points[i];
      final x = (p.beat / widget.clip.lengthBeats) * size.width;
      final y = size.height - p.value.clamp(0.0, 1.0) * size.height;
      if ((local - Offset(x, y)).distance <= hitRadius) {
        return i;
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details, Size size) {
    _dragIndex = _hitTestPoint(details.localPosition, size);
    if (_dragIndex != null) {
      HapticFeedback.selectionClick();
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final index = _dragIndex;
    if (index == null) return;
    final beat = (details.localPosition.dx / size.width * widget.clip.lengthBeats)
        .clamp(0.0, widget.clip.lengthBeats);
    final value =
        (1.0 - details.localPosition.dy / size.height).clamp(0.0, 1.0);
    _updatePoint(index, beat: beat, value: value);
  }

  void _onPanEnd(DragEndDetails details) {
    _dragIndex = null;
  }

  void _onDoubleTapDown(TapDownDetails details, Size size) {
    if (_hitTestPoint(details.localPosition, size) != null) return;
    final beat = (details.localPosition.dx / size.width * widget.clip.lengthBeats)
        .clamp(0.0, widget.clip.lengthBeats);
    final value =
        (1.0 - details.localPosition.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _activeShape = null;
      _points.add(AutomationPointSnapshot(beat: beat, value: value));
      _points.sort((a, b) => a.beat.compareTo(b.beat));
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.clip.isLinked
        ? '${widget.trackName} · ${widget.clip.linkLabel}'
        : '${widget.trackName} · Automation';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pick a shape below or drag points · double-tap to add',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
            ),
            const SizedBox(height: 10),
            _ShapeToolbar(
              activeShape: _activeShape,
              params: _shapeParams,
              onShapeSelected: _selectShape,
              onParamsChanged: _setShapeParams,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onPanStart: (d) => _onPanStart(d, size),
                    onPanUpdate: (d) => _onPanUpdate(d, size),
                    onPanEnd: _onPanEnd,
                    onDoubleTapDown: (d) => _onDoubleTapDown(d, size),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: LibraryTheme.accentAutomation.withValues(alpha: 0.35),
                        ),
                      ),
                      child: CustomPaint(
                        painter: _AutomationCurvePainter(
                          lengthBeats: widget.clip.lengthBeats,
                          points: _points,
                          accent: LibraryTheme.accentAutomation,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapeToolbar extends StatelessWidget {
  const _ShapeToolbar({
    required this.activeShape,
    required this.params,
    required this.onShapeSelected,
    required this.onParamsChanged,
  });

  final AutomationCurveShape? activeShape;
  final AutomationShapeParams params;
  final ValueChanged<AutomationCurveShape> onShapeSelected;
  final ValueChanged<AutomationShapeParams> onParamsChanged;

  static const _shapes = AutomationCurveShape.values;

  @override
  Widget build(BuildContext context) {
    final accent = LibraryTheme.accentAutomation;
    final showPeriodic = activeShape?.isPeriodic ?? false;
    final showDuty = activeShape?.usesDuty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final shape in _shapes)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ShapeChip(
                    label: shape.label,
                    selected: activeShape == shape,
                    accent: accent,
                    onTap: () => onShapeSelected(shape),
                  ),
                ),
            ],
          ),
        ),
        if (activeShape != null) ...[
          const SizedBox(height: 10),
          _ShapeSlider(
            label: 'Floor',
            value: params.min,
            onChanged: (v) => onParamsChanged(params.copyWith(min: v)),
          ),
          _ShapeSlider(
            label: 'Peak',
            value: params.max,
            onChanged: (v) => onParamsChanged(params.copyWith(max: v)),
          ),
          if (showPeriodic) ...[
            _ShapeSlider(
              label: 'Cycles',
              value: params.cycles,
              min: 0.25,
              max: 16,
              divisions: 63,
              display: params.cycles.toStringAsFixed(2),
              onChanged: (v) => onParamsChanged(params.copyWith(cycles: v)),
            ),
            _ShapeSlider(
              label: 'Phase',
              value: params.phase,
              display: '${(params.phase * 100).round()}%',
              onChanged: (v) => onParamsChanged(params.copyWith(phase: v)),
            ),
          ],
          if (showDuty)
            _ShapeSlider(
              label: 'Pulse width',
              value: params.duty,
              min: 0.05,
              max: 0.95,
              display: '${(params.duty * 100).round()}%',
              onChanged: (v) => onParamsChanged(params.copyWith(duty: v)),
            ),
        ],
      ],
    );
  }
}

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.22) : const Color(0xFF1A1A24),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? accent : Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapeSlider extends StatelessWidget {
  const _ShapeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions = 100,
    this.display,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int divisions;
  final String? display;

  @override
  Widget build(BuildContext context) {
    final accent = LibraryTheme.accentAutomation;
    final shown = display ?? value.toStringAsFixed(2);

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            shown,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _AutomationCurvePainter extends CustomPainter {
  const _AutomationCurvePainter({
    required this.lengthBeats,
    required this.points,
    required this.accent,
  });

  final double lengthBeats;
  final List<AutomationPointSnapshot> points;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (points.isEmpty || lengthBeats <= 0) return;

    final sorted = List<AutomationPointSnapshot>.of(points)
      ..sort((a, b) => a.beat.compareTo(b.beat));

    final path = Path();
    for (var i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      final x = (p.beat / lengthBeats) * size.width;
      final y = size.height - p.value.clamp(0.0, 1.0) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    for (final p in sorted) {
      final x = (p.beat / lengthBeats) * size.width;
      final y = size.height - p.value.clamp(0.0, 1.0) * size.height;
      canvas.drawCircle(Offset(x, y), 7, Paint()..color = accent);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _AutomationCurvePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lengthBeats != lengthBeats;
  }
}
