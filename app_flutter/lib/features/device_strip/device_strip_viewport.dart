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
  });

  final Widget child;
  final double designWidth;
  final double designHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(1.0, constraints.maxWidth / designWidth);
        final width = designWidth * scale;
        final height = designHeight * scale;

        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
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
            ),
          ),
        );
      },
    );
  }
}
