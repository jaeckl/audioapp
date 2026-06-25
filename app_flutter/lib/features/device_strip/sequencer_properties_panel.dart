import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'modulator_rate_codec.dart';
import 'modulator_types.dart';
import 'rotary_knob.dart';
import 'sequencer_step_editor.dart';

class SequencerPropertiesPanel extends StatelessWidget {
  const SequencerPropertiesPanel({
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
          // Header: name + polarity + step count
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: _sequencerHeader(theme),
          ),
          const SizedBox(height: 8),
          // Step bars — fill remaining vertical space.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SequencerStepEditor(
                stepValues: mod.stepValues,
                stepCount: mod.sequencerSteps,
                onStepChanged: (i, v) => onUpdate('step_$i', v),
                currentStep: null, // TODO: wire up from engine snapshot
              ),
            ),
          ),
          // Retrigger mode bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: _lfoSegmentBar(),
          ),
          // Sync divisions (only when sync active)
          if (_isSync)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: _lfoSyncDivisions(),
            ),
          // Knobs pinned to bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: _sequencerKnobs(),
          ),
        ],
      ),
    );
  }

  Widget _sequencerHeader(ThemeData theme) {
    final stepOptions = [4, 8, 12, 16, 24, 32];
    final currentSteps = stepOptions.contains(mod.sequencerSteps)
        ? mod.sequencerSteps
        : 16;
    return Row(
      children: [
        Text(
          'SEQ ${mod.id}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        _polarityToggle(),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: currentSteps,
          dropdownColor: const Color(0xFF1A1A24),
          isDense: true,
          style: const TextStyle(
            color: accent,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          underline: const SizedBox(),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: accent,
            size: 14,
          ),
          items: stepOptions
              .map((n) => DropdownMenuItem<int>(
                    value: n,
                    child: Text(
                      '$n',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onUpdate('steps', v.toDouble());
          },
        ),
      ],
    );
  }

  /// 4-knob row: Rate, Direction, Shape, Smoothing
  Widget _sequencerKnobs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _seqKnob(
          'Rate',
          ModulatorRateCodec.formatRate(mod),
          mod.rate.clamp(0.0, 1.0),
          (v) => onUpdate('rate', v),
        ),
        _seqKnob(
          'Dir',
          ModulatorTypes.sequencerDirectionLabels[
              mod.sequencerDirection.clamp(0, 3)],
          mod.sequencerDirection.clamp(0, 3) / 3.0,
          (v) => onUpdate('direction', (v * 3).round().toDouble()),
        ),
        _seqKnob(
          'Shape',
          ModulatorTypes.sequencerShapeLabels[
              mod.sequencerShape.clamp(0, 2)],
          mod.sequencerShape.clamp(0, 2) / 2.0,
          (v) => onUpdate('shape', (v * 2).round().toDouble()),
        ),
        _seqKnob(
          'Sm',
          '${(mod.smoothing.clamp(0.0, 1.0) * 100).round()}%',
          mod.smoothing.clamp(0.0, 1.0),
          (v) => onUpdate('smoothing', v),
        ),
      ],
    );
  }

  Widget _seqKnob(
    String label,
    String displayValue,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Expanded(
      child: Center(
        child: RotaryKnob(
          label: label,
          value: value,
          displayValue: displayValue,
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
}
