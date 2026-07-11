import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'subtractive_waveform_preview_wave_painter.dart';

/// Static waveform preview — morphs continuously with [shape] 0..1.
class SubtractiveWaveformPreview extends StatelessWidget {
  const SubtractiveWaveformPreview({
    super.key,
    required this.shape,
    required this.accent,
    this.height = 52,
    this.showLabel = true,
  });

  final double shape;
  final Color accent;
  final double height;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : height;
        final resolvedWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : double.infinity;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                size: Size(resolvedWidth, resolvedHeight),
                painter: _WavePainter(shape: shape, color: accent),
              ),
              if (showLabel)
                Positioned(
                  left: 6,
                  top: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      child: Text(
                        subtractiveShapeLabel(shape),
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.95),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

String subtractiveShapeLabel(double shape) {
  const names = ['Sine', 'Tri', 'Saw', 'Sqr', 'Pls'];
  return names[(shape * 4).round().clamp(0, 4)];
}
