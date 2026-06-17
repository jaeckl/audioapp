import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device_strip_metrics.dart';

/// Scales device strip UIs uniformly at a fixed design size — never stretches to
/// fill extra horizontal space (e.g. landscape).
class DeviceStripViewport extends StatelessWidget {
  const DeviceStripViewport({
    super.key,
    required this.child,
    this.designWidth = DeviceStripMetrics.designWidth,
    this.designHeight = DeviceStripMetrics.height,
    this.shrinkWrap = false,
  });

  final Widget child;
  final double designWidth;
  final double designHeight;

  /// When true, sizes to the scaled design dimensions instead of filling the parent.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : designWidth;
        final scale = math.min(1.0, maxWidth / designWidth);
        final width = designWidth * scale;
        final height = designHeight * scale;

        final content = SizedBox(
          width: width,
          height: height,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: child,
            ),
          ),
        );

        if (shrinkWrap) {
          return content;
        }

        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: Align(
            alignment: Alignment.topLeft,
            child: content,
          ),
        );
      },
    );
  }
}
