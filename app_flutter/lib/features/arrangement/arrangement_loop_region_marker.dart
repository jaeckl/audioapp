import 'package:flutter/material.dart';

import '../piano_roll/piano_roll_metrics.dart';

/// Baby-blue loop region markers (ruler pill + lane line).
abstract final class ArrangementLoopRegionTheme {
  static const Color color = Color(0xFF89CFF0);
  static const double pillSize = 14;
  static const double hitWidth = 20;
}

class ArrangementLoopRegionPill extends StatelessWidget {
  const ArrangementLoopRegionPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: ArrangementLoopRegionTheme.pillSize,
        height: ArrangementLoopRegionTheme.pillSize,
        decoration: BoxDecoration(
          color: ArrangementLoopRegionTheme.color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.drag_indicator,
          size: ArrangementLoopRegionTheme.pillSize - 2,
          color: Color(0xFF1A3A4A),
        ),
      ),
    );
  }
}

class ArrangementLoopRegionLine extends StatelessWidget {
  const ArrangementLoopRegionLine({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: PianoRollMetrics.clipEndLineWidth,
          color: ArrangementLoopRegionTheme.color,
        ),
      ),
    );
  }
}
