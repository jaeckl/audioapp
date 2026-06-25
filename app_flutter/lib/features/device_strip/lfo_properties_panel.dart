import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'lfo_preview_painter.dart';
import 'modulator_rate_codec.dart';
import 'modulator_types.dart';
import 'rotary_knob.dart';

class LfoPropertiesPanel extends StatelessWidget {
  const LfoPropertiesPanel({
    super.key,
    required this.mod,
    required this.onUpdate,
  });

  final LfoSnapshot mod;
  final Future<void> Function(String param, double value) onUpdate;

  static const accent = Color(0xFFE8A54B);
  static const syncLabels = ['1/1', '1/2', '1/4', '1/8', '1/16'];

  bool get _isSync => mod.retrigger == ModulatorTypes.retriggerSync;

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
            child: Row(
              children: [
                Text(
                  'LFO ${mod.id}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Preview fills remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LfoPreviewWidget(
                morph: mod.morph,
                spread: mod.spread,
                polarity: mod.polarity,
                analogMode: mod.analogMode,
                onChanged: (param, value) => onUpdate(param, value),
              ),
            ),
          ),
          // Retrigger mode — segmented button bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: _lfoSegmentBar(),
          ),
          // Sync divisions — segmented bar (only when sync active)
          if (_isSync)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: _lfoSyncDivisions(),
            ),
          // Knobs pinned to bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: _lfoKnobs(),
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

  /// Sync division chips — only visible when `_isSync`.
  Widget _lfoSyncDivisions() {
    return Row(
      children: List.generate(syncLabels.length, (i) {
        final active = (mod.syncDivision.clamp(1, 5) - 1) == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => onUpdate('syncDivision', (i + 1).toDouble()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: active ? accent.withValues(alpha: 0.2) : const Color(0xFF1A1A24),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: active ? accent : Colors.white24,
                  width: active ? 1.0 : 0.5,
                ),
              ),
              child: Text(
                syncLabels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? accent : Colors.white54,
                  fontSize: 8,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _lfoKnobs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _lfoKnob('Rate', ModulatorRateCodec.formatRate(mod), mod.rate, (v) => onUpdate('rate', v)),
        _lfoKnob('Phase', '${(mod.phase * 360).round()}\u00B0', mod.phase, (v) => onUpdate('phase', v)),
        _lfoKnob('Shape', '${(mod.morph * 100).round()}%', mod.morph, (v) => onUpdate('morph', v)),
        _lfoKnob('Skew', '${(mod.spread * 100).round()}%', mod.spread, (v) => onUpdate('spread', v)),
      ],
    );
  }

  Widget _lfoKnob(String label, String displayValue, double value, ValueChanged<double> onChanged) {
    return Expanded(
      child: Center(
        child: RotaryKnob(
          label: label,
          value: value.clamp(0.0, 1.0),
          displayValue: displayValue,
          size: DeviceKnobSizes.compact,
          accentColor: accent,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
