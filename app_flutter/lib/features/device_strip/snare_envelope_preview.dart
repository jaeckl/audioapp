import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'snare_envelope_preview_snare_envelope_painter.dart';

/// Dual-layer body + snares preview for the snare generator strip.
class SnareEnvelopePreview extends StatelessWidget {
  const SnareEnvelopePreview({
    super.key,
    required this.body,
    required this.ring,
    required this.tune,
    required this.snares,
    required this.snap,
    required this.decay,
    required this.accent,
  });

  final double body;
  final double ring;
  final double tune;
  final double snares;
  final double snap;
  final double decay;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SnareEnvelopePainter(
        body: body,
        ring: ring,
        tune: tune,
        snares: snares,
        snap: snap,
        decay: decay,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

String snareTuneLabel(double norm) {
  final hz = (120 + norm.clamp(0.0, 1.0) * 160).round();
  return '$hz Hz';
}

String snareDecayLabel(double norm) {
  final ms = (150 + (1 - norm.clamp(0.0, 1.0)) * 350).round();
  return '${ms}ms';
}
