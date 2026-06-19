import 'package:flutter/material.dart';

import 'modulator_polarity.dart';

/// White modulation depth indicator — right-aligned inside a spinner border.
class ModulationVerticalBar extends StatelessWidget {
  const ModulationVerticalBar({
    super.key,
    required this.polarity,
    required this.amount,
    this.inAssignment = false,
    this.barWidth = 3,
    this.inset = 3,
  });

  final ModulatorPolarity polarity;
  final double amount;
  final bool inAssignment;
  final double barWidth;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final depth = modulationBarDepth(polarity: polarity, amount: amount);
    if (depth <= 0) return const SizedBox.shrink();

    final color = Colors.white.withValues(alpha: inAssignment ? 0.85 : 0.55);

    return Positioned(
      right: inset,
      top: inset,
      bottom: inset,
      width: barWidth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerH = constraints.maxHeight;
          final barH = (innerH * depth).clamp(0.0, innerH);
          final top = switch (polarity) {
            ModulatorPolarity.bipolar => (innerH - barH) / 2,
            ModulatorPolarity.positive => innerH - barH,
            ModulatorPolarity.negative => 0.0,
          };
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: top,
                left: 0,
                right: 0,
                height: barH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
