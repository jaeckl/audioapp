import 'package:flutter/material.dart';

import 'drum_panel_widgets.dart';

/// Fill: length | intensity + style | apply — grouped rows.
class DrumFillToolPanel extends StatelessWidget {
  const DrumFillToolPanel({
    super.key,
    required this.fillLengthBeats,
    required this.intensity,
    required this.style,
    required this.onFillLengthChanged,
    required this.onIntensityChanged,
    required this.onStyleChanged,
    required this.onApply,
  });

  final double fillLengthBeats;
  final double intensity;
  final String style;
  final ValueChanged<double> onFillLengthChanged;
  final ValueChanged<double> onIntensityChanged;
  final ValueChanged<String> onStyleChanged;
  final VoidCallback onApply;

  static const _lengths = <(double, String)>[
    (1.0, '1 beat'),
    (2.0, '2 beats'),
    (4.0, '1 bar'),
    (8.0, '2 bars'),
  ];

  static const _styles = <(String, String)>[
    ('roll', 'Roll'),
    ('build', 'Build'),
    ('crash', 'Crash'),
    ('break', 'Break'),
  ];

  @override
  Widget build(BuildContext context) {
    final pct = (intensity * 100).round();

    return DrumPanelShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DrumControlGroup(
            title: 'Length',
            child: DrumWrapRow(
              children: [
                for (final (beats, label) in _lengths)
                  DrumPill(
                    label: label,
                    active: (fillLengthBeats - beats).abs() < 1e-9,
                    onTap: () => onFillLengthChanged(beats),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DrumControlGroup(
                title: 'Intensity',
                child: DrumValueStepper(
                  label: 'Int',
                  display: '$pct%',
                  canDecrement: intensity > 0.05,
                  canIncrement: intensity < 1,
                  onDecrement: () =>
                      onIntensityChanged((intensity - 0.05).clamp(0.0, 1.0)),
                  onIncrement: () =>
                      onIntensityChanged((intensity + 0.05).clamp(0.0, 1.0)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DrumControlGroup(
                  title: 'Style',
                  child: DrumWrapRow(
                    children: [
                      for (final (id, label) in _styles)
                        DrumPill(
                          label: label,
                          active: style == id,
                          onTap: () => onStyleChanged(id),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DrumControlGroup(
                title: 'Write',
                child: DrumPill(label: 'Apply', active: true, onTap: onApply),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
