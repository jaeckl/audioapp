import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'rotary_knob.dart';

class RandomPropertiesPanel extends StatelessWidget {
  const RandomPropertiesPanel({
    super.key,
    required this.mod,
    required this.onUpdate,
  });

  final LfoSnapshot mod;
  final Future<void> Function(String param, double value) onUpdate;

  static const accent = Color(0xFFE8A54B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: const Color(0xFF14141C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              'RND ${mod.id}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Retrigger mode — segmented button bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: _lfoSegmentBar(),
          ),
          // Knobs row: Rate + Smoothing
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _rndKnob('Rate', mod.rate, (v) => onUpdate('rate', v)),
                _rndKnob('Sm', mod.smoothing, (v) => onUpdate('smoothing', v)),
              ],
            ),
          ),
          // Polarity toggle at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: _polarityToggle(),
          ),
        ],
      ),
    );
  }

  /// Retrigger mode bar: Free, Sync, On note.
  Widget _lfoSegmentBar() {
    const labels = ['Free', 'Sync', 'On note'];
    const values = [0, 1, 2];
    final selected = mod.retrigger.clamp(0, 2);
    return SizedBox(
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                Expanded(
                  child: Material(
                    color: selected == values[i]
                        ? accent.withValues(alpha: 0.2)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => onUpdate('retrigger', values[i].toDouble()),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: selected == values[i] ? accent : Colors.white38,
                            fontSize: 9,
                            fontWeight:
                                selected == values[i] ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _rndKnob(String label, double value, ValueChanged<double> onChanged) {
    return Expanded(
      child: Center(
        child: RotaryKnob(
          label: label,
          value: value.clamp(0.0, 1.0),
          displayValue: value.toStringAsFixed(2),
          size: DeviceKnobSizes.compact,
          accentColor: accent,
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Small 2-segment polarity toggle: ± and +.
  Widget _polarityToggle() {
    const labels = ['\u00B1', '+'];
    const values = [0, 1];
    final selected = mod.polarity.clamp(0, 1);
    return SizedBox(
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                Expanded(
                  child: Material(
                    color: selected == values[i]
                        ? accent.withValues(alpha: 0.2)
                        : Colors.transparent,
                    child: InkWell(
                      onTap: () => onUpdate('polarity', values[i].toDouble()),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: selected == values[i] ? accent : Colors.white38,
                            fontSize: 9,
                            fontWeight:
                                selected == values[i] ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
