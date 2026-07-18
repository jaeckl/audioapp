import 'package:flutter/material.dart';

import 'drum_panel_widgets.dart';

/// Groove: amount controls | ratchet | bake actions — grouped rows.
class DrumGrooveToolPanel extends StatelessWidget {
  const DrumGrooveToolPanel({
    super.key,
    required this.probability,
    required this.ratchet,
    required this.humanize,
    required this.onProbabilityChanged,
    required this.onRatchetChanged,
    required this.onHumanizeChanged,
    required this.onDice,
    required this.onRatchet,
    required this.onHumanize,
    this.laneLabel,
  });

  final double probability;
  final int ratchet;
  final double humanize;
  final ValueChanged<double> onProbabilityChanged;
  final ValueChanged<int> onRatchetChanged;
  final ValueChanged<double> onHumanizeChanged;
  final VoidCallback onDice;
  final VoidCallback onRatchet;
  final VoidCallback onHumanize;
  final String? laneLabel;

  static const _ratchets = [2, 3, 4, 8];

  @override
  Widget build(BuildContext context) {
    final pct = (probability * 100).round();
    final human = humanize.round();

    return DrumPanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (laneLabel != null) ...[
                DrumControlGroup(
                  title: 'Lane',
                  child: DrumLaneTag(label: laneLabel!),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: DrumControlGroup(
                  title: 'Amounts',
                  child: DrumWrapRow(
                    children: [
                      DrumValueStepper(
                        label: 'Prob',
                        display: '$pct%',
                        canDecrement: probability > 0.05,
                        canIncrement: probability < 1,
                        onDecrement: () => onProbabilityChanged(
                          (probability - 0.05).clamp(0.0, 1.0),
                        ),
                        onIncrement: () => onProbabilityChanged(
                          (probability + 0.05).clamp(0.0, 1.0),
                        ),
                      ),
                      DrumValueStepper(
                        label: 'Human',
                        display: '±$human',
                        canDecrement: humanize > 0,
                        canIncrement: humanize < 40,
                        onDecrement: () => onHumanizeChanged(
                          (humanize - 2).clamp(0.0, 40.0),
                        ),
                        onIncrement: () => onHumanizeChanged(
                          (humanize + 2).clamp(0.0, 40.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DrumControlGroup(
                  title: 'Ratchet',
                  child: DrumWrapRow(
                    children: [
                      for (final r in _ratchets)
                        DrumPill(
                          label: 'x$r',
                          active: ratchet == r,
                          onTap: () => onRatchetChanged(r),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DrumControlGroup(
                title: 'Bake',
                child: DrumWrapRow(
                  children: [
                    DrumPill(label: 'Dice', onTap: onDice),
                    DrumPill(label: 'Ratchet', onTap: onRatchet),
                    DrumPill(label: 'Humanize', onTap: onHumanize),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
