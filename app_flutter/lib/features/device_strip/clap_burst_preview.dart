import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'clap_burst_preview_clap_burst_painter.dart';

/// Staggered burst timeline preview for the clap generator strip.
class ClapBurstPreview extends StatelessWidget {
  const ClapBurstPreview({
    super.key,
    required this.bursts,
    required this.spread,
    required this.decay,
    required this.accent,
  });

  final double bursts;
  final double spread;
  final double decay;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ClapBurstPainter(
        bursts: bursts,
        spread: spread,
        decay: decay,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

String clapBurstsLabel(double norm) {
  final count = 2 + (norm.clamp(0.0, 1.0) * 3).round();
  return '$count hits';
}

String clapDecayLabel(double norm) {
  final ms = (120 + (1 - norm.clamp(0.0, 1.0)) * 380).round();
  return '${ms}ms';
}
