import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'midi_lane_layout.dart';
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
    this.lanes,
  });

  final double virtualLengthBeats;
  final double clipLengthBeats;
  final int minPitch;
  final int maxPitch;
  final double pixelsPerBeat;
  final double rowHeight;
  final PianoRollScaleSettings scaleSettings;
  final List<MidiLaneDefinition>? lanes;

  Iterable<({int pitch, int row, bool enabled})> get _rows sync* {
    if (lanes != null) {
      for (var row = 0; row < lanes!.length; row++) {
        yield (
          pitch: lanes![row].pitch,
          row: row,
          enabled: lanes![row].enabled,
        );
      }
      return;
    }
    for (var pitch = maxPitch; pitch >= minPitch; pitch--) {
      yield (pitch: pitch, row: maxPitch - pitch, enabled: true);
    }
  }

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
    for (final entry in _rows) {
      final pitch = entry.pitch;
      final y = entry.row * rowHeight;
      final isBlack = PianoRollNoteOps.isBlackKey(pitch);
      final isDrumLane = lanes != null;
      final rowColor = isDrumLane
          ? (entry.row.isEven
              ? const Color(0xFF24242D)
              : const Color(0xFF202029))
          : (!entry.enabled
              ? PianoRollTheme.surface
              : isBlack
                  ? PianoRollTheme.blackKeyRow
                  : PianoRollTheme.whiteKeyRow);
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, rowHeight),
        Paint()
          ..color = isDrumLane
              ? rowColor.withValues(alpha: entry.enabled ? 0.72 : 0.45)
              : rowColor.withValues(
                  alpha: entry.enabled ? (isBlack ? 0.14 : 0.05) : 0.4,
                ),
      );
      canvas.drawLine(
        Offset(0, y + rowHeight),
        Offset(size.width, y + rowHeight),
        Paint()
          ..color = isDrumLane
              ? const Color(0xFF41414F)
              : (isBlack ? Colors.black : Colors.white).withValues(alpha: 0.05)
          ..strokeWidth = isDrumLane ? 1 : 0.5,
      );
    }
  }

  void _paintScaleRows(Canvas canvas, Size size) {
    if (!scaleSettings.highlight || lanes != null) return;
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
        oldDelegate.scaleSettings != scaleSettings ||
        oldDelegate.lanes != lanes;
  }
}
