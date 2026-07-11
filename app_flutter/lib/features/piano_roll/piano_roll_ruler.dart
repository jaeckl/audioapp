import 'package:flutter/material.dart';

import 'piano_roll_metrics.dart';
import 'piano_roll_theme.dart';

part 'piano_roll_ruler_ruler_painter.dart';

class PianoRollRuler extends StatelessWidget {
  const PianoRollRuler({
    super.key,
    required this.virtualLengthBeats,
    required this.clipLengthBeats,
    required this.pixelsPerBeat,
    this.regionStartBeat = 0,
    this.highlightColor,
  });

  final double virtualLengthBeats;
  final double clipLengthBeats;
  final double pixelsPerBeat;
  final double regionStartBeat;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final width = PianoRollMetrics.gridWidth(virtualLengthBeats, pixelsPerBeat);
    final barCount = (virtualLengthBeats / PianoRollMetrics.beatsPerBar).ceil();

    return SizedBox(
      width: width,
      height: PianoRollMetrics.rulerHeight,
      child: CustomPaint(
        painter: _RulerPainter(
          barCount: barCount,
          clipLengthBeats: clipLengthBeats,
          regionStartBeat: regionStartBeat,
          highlightColor: highlightColor,
          pixelsPerBeat: pixelsPerBeat,
        ),
      ),
    );
  }
}
