import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../piano_roll/piano_roll_metrics.dart';
import 'automation_editor_metrics.dart';
import 'automation_editor_theme.dart';

class AutomationCurveGridPainter extends CustomPainter {
  AutomationCurveGridPainter({
    required this.virtualLengthBeats,
    required this.clipLengthBeats,
    required this.pixelsPerBeat,
    required this.points,
    required this.selectedIndices,
    required this.deleteMarkedIndices,
    this.insertHighlightStartBeat,
    this.insertHighlightEndBeat,
  });

  final double virtualLengthBeats;
  final double clipLengthBeats;
  final double pixelsPerBeat;
  final List<AutomationPointSnapshot> points;
  final Set<int> selectedIndices;
  final Set<int> deleteMarkedIndices;
  final double? insertHighlightStartBeat;
  final double? insertHighlightEndBeat;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AutomationEditorTheme.surface,
    );

    final clipWidth = clipLengthBeats * pixelsPerBeat;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, clipWidth, size.height),
      Paint()..color = AutomationEditorTheme.clipRegionFill,
    );
    if (clipWidth < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(clipWidth, 0, size.width - clipWidth, size.height),
        Paint()..color = AutomationEditorTheme.outsideClipDim,
      );
    }

    _paintInsertHighlight(canvas, size);
    _paintValueGrid(canvas, size);
    _paintBeatGrid(canvas, size);
    _paintCurve(canvas, size);
    _paintClipBoundary(canvas, size);
  }

  void _paintInsertHighlight(Canvas canvas, Size size) {
    final start = insertHighlightStartBeat;
    final end = insertHighlightEndBeat;
    if (start == null || end == null || end <= start) return;

    final left = start * pixelsPerBeat;
    final width = (end - start) * pixelsPerBeat;
    canvas.drawRect(
      Rect.fromLTWH(left, 0, width, size.height),
      Paint()..color = AutomationEditorTheme.accent.withValues(alpha: 0.1),
    );
  }

  void _paintValueGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AutomationEditorTheme.gridValue
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 4; i++) {
      final value = 1.0 - i / 4;
      final y = AutomationEditorMetrics.dyFromValue(value, size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintBeatGrid(Canvas canvas, Size size) {
    final barStep = PianoRollMetrics.beatsPerBar.toDouble();
    for (var beat = 0.0; beat <= virtualLengthBeats; beat += 1.0) {
      final x = beat * pixelsPerBeat;
      if (x > size.width) break;
      final isBar = (beat % barStep).abs() < 0.001;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = isBar ? AutomationEditorTheme.gridBar : AutomationEditorTheme.gridBeat
          ..strokeWidth = isBar ? 1 : 0.5,
      );
    }
  }

  void _paintCurve(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final sorted = List<AutomationPointSnapshot>.of(points)
      ..sort((a, b) => a.beat.compareTo(b.beat));

    final path = Path();
    for (var i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      final x = p.beat * pixelsPerBeat;
      final y = AutomationEditorMetrics.dyFromValue(p.value, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AutomationEditorTheme.curveStroke
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = p.beat * pixelsPerBeat;
      final y = AutomationEditorMetrics.dyFromValue(p.value, size.height);
      final selected = selectedIndices.contains(i);
      final markedDelete = deleteMarkedIndices.contains(i);

      canvas.drawCircle(
        Offset(x, y),
        AutomationEditorMetrics.nodeRadius,
        Paint()
          ..color = markedDelete
              ? AutomationEditorTheme.saveError
              : AutomationEditorTheme.nodeFill,
      );
      canvas.drawCircle(
        Offset(x, y),
        selected ? 5 : 4,
        Paint()
          ..color = selected
              ? AutomationEditorTheme.nodeSelected
              : Colors.white,
      );
    }
  }

  void _paintClipBoundary(Canvas canvas, Size size) {
    final x = clipLengthBeats * pixelsPerBeat;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = AutomationEditorTheme.clipBoundary.withValues(alpha: 0.7)
        ..strokeWidth = PianoRollMetrics.clipBoundaryWidth,
    );
  }

  @override
  bool shouldRepaint(covariant AutomationCurveGridPainter oldDelegate) {
    return oldDelegate.virtualLengthBeats != virtualLengthBeats ||
        oldDelegate.clipLengthBeats != clipLengthBeats ||
        oldDelegate.pixelsPerBeat != pixelsPerBeat ||
        oldDelegate.points != points ||
        oldDelegate.selectedIndices != selectedIndices ||
        oldDelegate.deleteMarkedIndices != deleteMarkedIndices ||
        oldDelegate.insertHighlightStartBeat != insertHighlightStartBeat ||
        oldDelegate.insertHighlightEndBeat != insertHighlightEndBeat;
  }
}
