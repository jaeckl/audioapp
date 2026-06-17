import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'piano_roll_theme.dart';

class PianoRollGridPainter extends CustomPainter {
  PianoRollGridPainter({
    required this.virtualLengthBeats,
    required this.clipLengthBeats,
    required this.minPitch,
    required this.maxPitch,
    required this.pixelsPerBeat,
    required this.rowHeight,
  });

  final double virtualLengthBeats;
  final double clipLengthBeats;
  final int minPitch;
  final int maxPitch;
  final double pixelsPerBeat;
  final double rowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    _paintCanvasBackground(canvas, size);
    _paintClipRegions(canvas, size);
    _paintVerticalGrid(canvas, size);
    _paintClipBoundaries(canvas, size);
  }

  void _paintCanvasBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = PianoRollTheme.surface,
    );
  }

  void _paintClipRegions(Canvas canvas, Size size) {
    final clipWidth = clipLengthBeats * pixelsPerBeat;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, clipWidth, size.height),
      Paint()..color = PianoRollTheme.clipRegionFill,
    );
    if (clipWidth < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(clipWidth, 0, size.width - clipWidth, size.height),
        Paint()..color = PianoRollTheme.outsideClipDim,
      );
    }
  }

  void _paintVerticalGrid(Canvas canvas, Size size) {
    final barStep = PianoRollMetrics.beatsPerBar.toDouble();

    for (var beat = 0.0; beat <= virtualLengthBeats; beat += 1.0) {
      final x = beat * pixelsPerBeat;
      if (x > size.width) break;

      final isBar = (beat % barStep).abs() < 0.001;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = isBar ? PianoRollTheme.gridBar : PianoRollTheme.gridBeat
          ..strokeWidth = isBar ? 1 : 0.5,
      );
    }
  }

  void _paintClipBoundaries(Canvas canvas, Size size) {
    final boundary = Paint()
      ..color = PianoRollTheme.clipBoundary.withValues(alpha: 0.7)
      ..strokeWidth = PianoRollMetrics.clipBoundaryWidth;

    final clipX = clipLengthBeats * pixelsPerBeat;
    canvas.drawLine(Offset(clipX, 0), Offset(clipX, size.height), boundary);
  }

  @override
  bool shouldRepaint(covariant PianoRollGridPainter oldDelegate) {
    return oldDelegate.virtualLengthBeats != virtualLengthBeats ||
        oldDelegate.clipLengthBeats != clipLengthBeats ||
        oldDelegate.minPitch != minPitch ||
        oldDelegate.maxPitch != maxPitch ||
        oldDelegate.pixelsPerBeat != pixelsPerBeat ||
        oldDelegate.rowHeight != rowHeight;
  }
}
