import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'modulator_math.dart';
import 'modulator_types.dart';

part 'modulator_preview_modulator_curve_painter.dart';

/// Square live preview of a modulator curve with a phase/playhead dot.
class ModulatorPreview extends StatelessWidget {
  const ModulatorPreview({
    super.key,
    required this.mod,
    required this.playheadBeat,
    required this.bpm,
    required this.elapsedSeconds,
    required this.accent,
    this.isSelected = false,
    this.isConnectMode = false,
    this.innerPadding = 2.0,
  });

  static const tileRadius = 6.0;
  static const plotRadius = 4.0;

  final LfoSnapshot mod;
  final double playheadBeat;
  final int bpm;
  final double elapsedSeconds;
  final Color accent;
  final bool isSelected;
  final bool isConnectMode;
  final double innerPadding;

  @override
  Widget build(BuildContext context) {
    final showBorder = isSelected || isConnectMode;
    final borderColor = isConnectMode
        ? accent
        : isSelected
            ? accent.withValues(alpha: 0.75)
            : Colors.transparent;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        borderRadius: BorderRadius.circular(tileRadius),
        border: showBorder
            ? Border.all(
                color: borderColor,
                width: isConnectMode ? 1.5 : 1.0,
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPadding),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(plotRadius),
          child: CustomPaint(
            painter: _ModulatorCurvePainter(
              mod: mod,
              playheadBeat: playheadBeat,
              bpm: bpm,
              elapsedSeconds: elapsedSeconds,
              accent: accent,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
