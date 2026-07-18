import 'package:flutter/material.dart';

import 'drum_panel_widgets.dart';

/// Pattern: Euclidean params | grid + rotate | actions — grouped rows.
class DrumPatternToolPanel extends StatelessWidget {
  const DrumPatternToolPanel({
    super.key,
    required this.hits,
    required this.steps,
    required this.rotate,
    required this.stepBeats,
    required this.onHitsChanged,
    required this.onStepsChanged,
    required this.onRotateChanged,
    required this.onStepBeatsChanged,
    required this.onApply,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onClear,
    this.laneLabel,
  });

  final int hits;
  final int steps;
  final int rotate;
  final double stepBeats;
  final ValueChanged<int> onHitsChanged;
  final ValueChanged<int> onStepsChanged;
  final ValueChanged<int> onRotateChanged;
  final ValueChanged<double> onStepBeatsChanged;
  final VoidCallback onApply;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onClear;
  final String? laneLabel;

  static const _grids = <(double, String)>[
    (0.125, '1/32'),
    (0.25, '1/16'),
    (0.5, '1/8'),
    (1.0, '1/4'),
  ];

  @override
  Widget build(BuildContext context) {
    final clampedHits = hits.clamp(0, steps);
    final maxRot = steps > 0 ? steps - 1 : 0;

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
                  title: 'Euclidean',
                  child: DrumWrapRow(
                    children: [
                      DrumValueStepper(
                        label: 'Hits',
                        display: '$clampedHits',
                        canDecrement: clampedHits > 0,
                        canIncrement: clampedHits < steps,
                        onDecrement: () => onHitsChanged(clampedHits - 1),
                        onIncrement: () => onHitsChanged(clampedHits + 1),
                      ),
                      DrumValueStepper(
                        label: 'Steps',
                        display: '$steps',
                        canDecrement: steps > 1,
                        canIncrement: steps < 32,
                        onDecrement: () {
                          final next = steps - 1;
                          onStepsChanged(next);
                          if (hits > next) onHitsChanged(next);
                          if (rotate >= next) {
                            onRotateChanged(next > 0 ? next - 1 : 0);
                          }
                        },
                        onIncrement: () => onStepsChanged(steps + 1),
                      ),
                      DrumValueStepper(
                        label: 'Rot',
                        display: '$rotate',
                        canDecrement: rotate > 0,
                        canIncrement: rotate < maxRot,
                        onDecrement: () => onRotateChanged(rotate - 1),
                        onIncrement: () => onRotateChanged(rotate + 1),
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
                  title: 'Grid',
                  child: DrumWrapRow(
                    children: [
                      for (final (beats, label) in _grids)
                        DrumPill(
                          label: label,
                          active: (stepBeats - beats).abs() < 1e-9,
                          onTap: () => onStepBeatsChanged(beats),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DrumControlGroup(
                title: 'Shift',
                child: DrumWrapRow(
                  children: [
                    DrumIconPill(
                      icon: Icons.rotate_left,
                      tooltip: 'Rotate left',
                      onTap: onRotateLeft,
                    ),
                    DrumIconPill(
                      icon: Icons.rotate_right,
                      tooltip: 'Rotate right',
                      onTap: onRotateRight,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              DrumControlGroup(
                title: 'Write',
                child: DrumWrapRow(
                  children: [
                    DrumPill(label: 'Clear', onTap: onClear),
                    DrumPill(label: 'Apply', active: true, onTap: onApply),
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
