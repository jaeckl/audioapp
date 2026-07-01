import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'piano_roll_note_ops.dart';
import 'piano_roll_scale.dart';
import 'piano_roll_theme.dart';

class PianoRollGridPainter extends CustomPainter {
  PianoRollGridPainter({
    required this.virtualLengthBeats,
    required this.clipLengthBeats,
    required this.minPitch,
    required this.maxPitch,
    required this.pixelsPerBeat,
    required this.rowHeight,
    required this.scaleSettings,
  });

  final double virtualLengthBeats;
  final double clipLengthBeats;
  final int minPitch;
  final int maxPitch;
  final double pixelsPerBeat;
  final double rowHeight;
  final PianoRollScaleSettings scaleSettings;

  @override
  void paint(Canvas canvas, Size size) {
    _paintCanvasBackground(canvas, size);
    _paintClipRegions(canvas, size);
    _paintKeyRowGuides(canvas, size);
    _paintScaleRows(canvas, size);
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

  void _paintKeyRowGuides(Canvas canvas, Size size) {
    for (var pitch = minPitch; pitch <= maxPitch; pitch++) {
      final y = (maxPitch - pitch) * rowHeight;
      final isBlack = PianoRollNoteOps.isBlackKey(pitch);
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, rowHeight),
        Paint()
          ..color = (isBlack
                  ? PianoRollTheme.blackKeyRow
                  : PianoRollTheme.whiteKeyRow)
              .withValues(alpha: isBlack ? 0.14 : 0.05),
      );
      canvas.drawLine(
        Offset(0, y + rowHeight),
        Offset(size.width, y + rowHeight),
        Paint()
          ..color =
              (isBlack ? Colors.black : Colors.white).withValues(alpha: 0.05)
          ..strokeWidth = 0.5,
      );
    }
  }

  void _paintScaleRows(Canvas canvas, Size size) {
    if (!scaleSettings.highlight) return;
    final scalePaint = Paint()
      ..color = PianoRollTheme.accent.withValues(alpha: 0.08);
    final rootPaint = Paint()
      ..color = PianoRollTheme.accent.withValues(alpha: 0.13);
    final rootEdge = Paint()
      ..color = PianoRollTheme.accent.withValues(alpha: 0.72);
    for (var pitch = minPitch; pitch <= maxPitch; pitch++) {
      if (!scaleSettings.isPitchInScale(pitch)) continue;
      final y = (maxPitch - pitch) * rowHeight;
      final isRoot = pitch % 12 == scaleSettings.rootPitchClass % 12;
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, rowHeight),
        isRoot ? rootPaint : scalePaint,
      );
      if (isRoot) {
        canvas.drawRect(Rect.fromLTWH(0, y, 3, rowHeight), rootEdge);
      }
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
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.scaleSettings != scaleSettings;
  }
}
