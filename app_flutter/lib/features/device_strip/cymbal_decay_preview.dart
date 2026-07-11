import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'cymbal_decay_preview_cymbal_decay_painter.dart';

/// Shimmering decay preview for the cymbal/crash generator strip.

class CymbalDecayPreview extends StatelessWidget {
  const CymbalDecayPreview({
    super.key,
    required this.color,
    required this.decay,
    required this.accent,
  });

  final double color;

  final double decay;

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CymbalDecayPainter(
        color: color,
        decay: decay,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

String cymbalDecayLabel(double norm) {
  final sec = 0.035 + norm.clamp(0.0, 1.0) * 0.70;

  return sec >= 1.0
      ? '${sec.toStringAsFixed(1)}s'
      : '${(sec * 1000).round()}ms';
}
