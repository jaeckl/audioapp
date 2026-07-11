import 'dart:math' as math;

import 'package:flutter/material.dart';

part 'subtractive_filter_preview_filter_response_painter.dart';

/// Static filter response sketch for the subtractive synth filter tab.
class SubtractiveFilterPreview extends StatelessWidget {
  const SubtractiveFilterPreview({
    super.key,
    required this.filterMode,
    required this.filterCutoff,
    required this.filterQ,
    required this.accent,
  });

  final int filterMode;
  final double filterCutoff;
  final double filterQ;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _FilterResponsePainter(
            filterMode: filterMode,
            filterCutoff: filterCutoff,
            filterQ: filterQ,
            color: accent,
          ),
        );
      },
    );
  }
}
