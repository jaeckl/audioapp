import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'kick_envelope_preview_kick_envelope_painter.dart';

/// Pitch-drop + amp envelope preview for the kick generator strip.
class KickEnvelopePreview extends StatelessWidget {
  const KickEnvelopePreview({
    super.key,
    required this.pitch,
    required this.punch,
    required this.decay,
    required this.click,
    required this.accent,
  });

  final double pitch;
  final double punch;
  final double decay;
  final double click;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _KickEnvelopePainter(
        pitch: pitch,
        punch: punch,
        decay: decay,
        click: click,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

String kickPitchLabel(double norm) {
  final hz = (80 + norm.clamp(0.0, 1.0) * 120).round();
  return '$hz Hz';
}

String kickDecayLabel(double norm) {
  final ms = (80 + (1 - norm.clamp(0.0, 1.0)) * 420).round();
  return '${ms}ms';
}
