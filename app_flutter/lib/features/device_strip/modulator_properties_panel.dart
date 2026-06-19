import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'modulator_rate_codec.dart';
import 'modulator_types.dart';
import 'rotary_knob.dart';

/// Knob-based side panel for the selected modulator (LFO / ADSR / ADR).
class ModulatorPropertiesPanel extends StatelessWidget {
  const ModulatorPropertiesPanel({
    super.key,
    required this.mod,
    required this.edges,
    required this.onUpdate,
    required this.onRemoveEdge,
  });

  final LfoSnapshot mod;
  final List<ModulationEdgeSnapshot> edges;
  final Future<void> Function(String param, double value) onUpdate;
  final Future<void> Function(int lfoId, String paramId) onRemoveEdge;

  static const accent = Color(0xFFE8A54B);
  static const syncLabels = ['1/1', '1/2', '1/4', '1/8', '1/16'];
  static const waveShort = ['Sin', 'Tri', 'Saw', 'Sq', 'Ramp'];

  bool get _isLfo => mod.modulatorType == ModulatorTypes.lfo;
  bool get _isAdsr => mod.modulatorType == ModulatorTypes.adsr;
  bool get _isSync => mod.retrigger == ModulatorTypes.retriggerSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: const Color(0xFF14141C),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ModulatorTypes.labelFor(mod.modulatorType).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${ModulatorTypes.labelFor(mod.modulatorType)} ${mod.id}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _sectionLabel('Retrigger'),
            const SizedBox(height: 4),
            _chipRow(
              labels: ModulatorTypes.retriggerLabels,
              selected: mod.retrigger.clamp(0, 2),
              onSelected: (v) => onUpdate('retrigger', v.toDouble()),
            ),
            if (_isLfo) ...[
              const SizedBox(height: 10),
              _sectionLabel('Waveform'),
              const SizedBox(height: 4),
              _chipRow(
                labels: waveShort,
                selected: mod.waveform.clamp(0, 4),
                onSelected: (v) => onUpdate('waveform', v.toDouble()),
                dense: true,
              ),
            ],
            const SizedBox(height: 10),
            _knobRow([
              RotaryKnob(
                label: ModulatorRateCodec.rateKnobLabel(mod),
                value: mod.rate.clamp(0.0, 1.0),
                displayValue: ModulatorRateCodec.formatRate(mod),
                size: DeviceKnobSizes.compact,
                accentColor: accent,
                onChanged: (v) => onUpdate('rate', v),
              ),
              if (_isLfo)
                RotaryKnob(
                  label: 'Phase',
                  value: mod.phase.clamp(0.0, 1.0),
                  displayValue: ModulatorRateCodec.formatPhase(mod.phase),
                  size: DeviceKnobSizes.compact,
                  accentColor: accent,
                  onChanged: (v) => onUpdate('phase', v),
                ),
            ]),
            if (_isSync) ...[
              const SizedBox(height: 8),
              _sectionLabel('Division'),
              const SizedBox(height: 4),
              _chipRow(
                labels: syncLabels,
                selected: (mod.syncDivision.clamp(1, 5) - 1),
                onSelected: (v) => onUpdate('syncDivision', (v + 1).toDouble()),
                dense: true,
              ),
            ],
            if (!_isLfo) ...[
              const SizedBox(height: 8),
              _knobRow([
                RotaryKnob(
                  label: 'Attack',
                  value: mod.attack.clamp(0.0, 1.0),
                  displayValue: ModulatorRateCodec.formatEnvelope(mod.attack),
                  size: DeviceKnobSizes.compact,
                  accentColor: accent,
                  onChanged: (v) => onUpdate('attack', v),
                ),
                RotaryKnob(
                  label: 'Decay',
                  value: mod.decay.clamp(0.0, 1.0),
                  displayValue: ModulatorRateCodec.formatEnvelope(mod.decay),
                  size: DeviceKnobSizes.compact,
                  accentColor: accent,
                  onChanged: (v) => onUpdate('decay', v),
                ),
              ]),
              const SizedBox(height: 4),
              _knobRow([
                if (_isAdsr)
                  RotaryKnob(
                    label: 'Sustain',
                    value: mod.sustain.clamp(0.0, 1.0),
                    displayValue: ModulatorRateCodec.formatEnvelope(mod.sustain),
                    size: DeviceKnobSizes.compact,
                    accentColor: accent,
                    onChanged: (v) => onUpdate('sustain', v),
                  ),
                RotaryKnob(
                  label: 'Release',
                  value: mod.release.clamp(0.0, 1.0),
                  displayValue: ModulatorRateCodec.formatEnvelope(mod.release),
                  size: DeviceKnobSizes.compact,
                  accentColor: accent,
                  onChanged: (v) => onUpdate('release', v),
                ),
              ]),
            ],
            const SizedBox(height: 10),
            _sectionLabel('Polarity'),
            const SizedBox(height: 4),
            _chipRow(
              labels: const ['±', '+', '−'],
              selected: mod.polarity.clamp(0, 2),
              onSelected: (v) => onUpdate('polarity', v.toDouble()),
              dense: true,
            ),
            if (edges.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionLabel('Targets'),
              const SizedBox(height: 4),
              ...edges.map(
                (edge) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          edge.paramId,
                          style: const TextStyle(color: Colors.white60, fontSize: 9),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(edge.amount * 100).round()}%',
                        style: const TextStyle(color: accent, fontSize: 9),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => onRemoveEdge(mod.id, edge.paramId),
                        child: const Icon(Icons.close, size: 12, color: Colors.white30),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _knobRow(List<Widget> knobs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < knobs.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(child: Center(child: knobs[i])),
        ],
      ],
    );
  }

  Widget _chipRow({
    required List<String> labels,
    required int selected,
    required ValueChanged<int> onSelected,
    bool dense = false,
  }) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(labels.length, (i) {
        final active = i == selected;
        return GestureDetector(
          onTap: () => onSelected(i),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 6 : 8,
              vertical: dense ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: active ? accent.withValues(alpha: 0.2) : const Color(0xFF1A1A24),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: active ? accent : Colors.white24,
                width: active ? 1.2 : 1,
              ),
            ),
            child: Text(
              labels[i],
              style: TextStyle(
                color: active ? accent : Colors.white54,
                fontSize: dense ? 9 : 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }),
    );
  }
}
