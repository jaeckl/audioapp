import 'package:flutter/material.dart';

import 'modulator_polarity.dart';

/// White modulation depth indicator — right-aligned inside a spinner border.
class ModulationVerticalBar extends StatelessWidget {
  const ModulationVerticalBar({
    super.key,
    required this.polarity,
    required this.amount,
    this.currentAmount,
    this.inAssignment = false,
    this.barWidth = 3,
    this.inset = 3,
  });

  final ModulatorPolarity polarity;
  final double amount;
  final double? currentAmount;
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
          final direction = modulationDisplayDirection(
            polarity: polarity,
            amount: amount,
          );
          final top = switch (polarity) {
            ModulatorPolarity.bipolar => (innerH - barH) / 2,
            _ => direction >= 0 ? innerH - barH : 0.0,
          };
          final live = currentAmount?.clamp(-1.0, 1.0);
          final liveH = live == null
              ? 0.0
              : (innerH *
                      live.abs() *
                      (polarity == ModulatorPolarity.bipolar ? 0.5 : 1.0))
                  .clamp(0.0, innerH);
          final liveTop = live == null
              ? 0.0
              : switch (polarity) {
                  ModulatorPolarity.bipolar =>
                    live >= 0 ? innerH / 2 - liveH : innerH / 2,
                  ModulatorPolarity.unipolar =>
                    live >= 0 ? innerH - liveH : 0.0,
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
              if (liveH > 0)
                Positioned(
                  top: liveTop,
                  left: 0,
                  right: 0,
                  height: liveH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
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
