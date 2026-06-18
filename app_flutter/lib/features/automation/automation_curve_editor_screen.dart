import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';

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
              'Drag points · double-tap empty area to add',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
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
