import 'package:flutter/material.dart';

import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/piano_roll_theme.dart';

/// Beat/bar grid background for arrangement track lanes — matches the piano roll canvas.
class ArrangementGridPainter extends CustomPainter {
  const ArrangementGridPainter({
    required this.virtualLengthBeats,
    required this.pixelsPerBeat,
    this.regionStartBeat = 0,
    this.regionEndBeat = 0,
    this.showRegionShading = false,
  });

  final double virtualLengthBeats;
  final double pixelsPerBeat;
  final double regionStartBeat;
  final double regionEndBeat;
  final bool showRegionShading;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = PianoRollTheme.surface,
    );

    if (showRegionShading && regionEndBeat > regionStartBeat) {
      final regionStartPx = regionStartBeat * pixelsPerBeat;
      final regionEndPx = regionEndBeat * pixelsPerBeat;
      canvas.drawRect(
        Rect.fromLTWH(regionStartPx, 0, regionEndPx - regionStartPx, size.height),
        Paint()..color = PianoRollTheme.clipRegionFill,
      );
      if (regionStartPx > 0) {
        canvas.drawRect(
          Rect.fromLTWH(0, 0, regionStartPx, size.height),
          Paint()..color = PianoRollTheme.outsideClipDim,
        );
      }
      if (regionEndPx < size.width) {
        canvas.drawRect(
          Rect.fromLTWH(regionEndPx, 0, size.width - regionEndPx, size.height),
          Paint()..color = PianoRollTheme.outsideClipDim,
        );
      }
    }

    _paintVerticalGrid(canvas, size);
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

  @override
  bool shouldRepaint(covariant ArrangementGridPainter oldDelegate) {
    return oldDelegate.virtualLengthBeats != virtualLengthBeats ||
        oldDelegate.pixelsPerBeat != pixelsPerBeat ||
        oldDelegate.regionStartBeat != regionStartBeat ||
        oldDelegate.regionEndBeat != regionEndBeat ||
        oldDelegate.showRegionShading != showRegionShading;
  }
}
