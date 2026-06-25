import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'envelope_preview_painter.dart';
import 'modulator_rate_codec.dart';
import 'modulator_types.dart';
import 'rotary_knob.dart';

class EnvelopePropertiesPanel extends StatelessWidget {
  const EnvelopePropertiesPanel({
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
            child: _envelopeHeader(theme),
          ),
          // Preview fills remaining space
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: EnvelopePreviewWidget(
                attack: mod.attack,
                hold: mod.hold,
                decay: mod.decay,
                sustain: mod.sustain,
                release: mod.release,
                curveType: mod.curveType,
                delay: mod.delay,
                attackCurve: mod.attackCurve,
                decayCurve: mod.decayCurve,
                releaseCurve: mod.releaseCurve,
                analogMode: mod.analogMode,
                onChanged: (param, value) => onUpdate(param, value),
              ),
            ),
          ),
          // Delay slider + knobs, anchored to bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: _delayBar(theme),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: _envelopeKnobs(),
          ),
        ],
      ),
    );
  }

  /// Inline delay bar with label and compact slider.
  Widget _delayBar(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            'Dl',
            style: TextStyle(
              color: accent.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: accent,
              inactiveTrackColor: const Color(0xFF33333D),
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: mod.delay.clamp(0.0, 1.0),
              onChanged: (v) => onUpdate('delay', v),
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            ModulatorRateCodec.formatEnvelope(mod.delay),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ),
      ],
    );
  }

  /// Header with curve-type combobox and modulator name for envelope modulators.
  Widget _envelopeHeader(ThemeData theme) {
    return Row(
      children: [
        DropdownButton<int>(
          value: mod.curveType.clamp(0, 3),
          dropdownColor: const Color(0xFF1A1A24),
          style: const TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: accent, size: 16),
          items: List.generate(ModulatorTypes.curveLabels.length, (i) {
            return DropdownMenuItem<int>(
              value: i,
              child: Text(
                ModulatorTypes.curveLabels[i],
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            );
          }),
          onChanged: (v) {
            if (v != null) onUpdate('curveType', v.toDouble());
          },
        ),
        const SizedBox(width: 6),
        Text(
          'Mod ${mod.id}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _envelopeKnobs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _envKnob('Atk', mod.attack, (v) => onUpdate('attack', v)),
        _envKnob('Hold', mod.hold, (v) => onUpdate('hold', v)),
        _envKnob('Dec', mod.decay, (v) => onUpdate('decay', v)),
        _envKnob('Sus', mod.sustain, (v) => onUpdate('sustain', v)),
        _envKnob('Rel', mod.release, (v) => onUpdate('release', v)),
      ],
    );
  }

  Widget _envKnob(String label, double value, ValueChanged<double> onChanged) {
    return Expanded(
      child: Center(
        child: RotaryKnob(
          label: label,
          value: value.clamp(0.0, 1.0),
          displayValue: ModulatorRateCodec.formatEnvelope(value),
          size: DeviceKnobSizes.compact,
          accentColor: accent,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
