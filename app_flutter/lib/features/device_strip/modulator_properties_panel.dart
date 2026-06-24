import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'envelope_preview_painter.dart';
import 'lfo_preview_painter.dart';
import 'modulator_rate_codec.dart';
import 'modulator_types.dart';
import 'rotary_knob.dart';

/// Properties panel for the selected modulator.
/// Shows LFO controls when type is LFO, envelope controls when type is envelope.
class ModulatorPropertiesPanel extends StatelessWidget {
  const ModulatorPropertiesPanel({
    super.key,
    required this.mod,
    required this.onUpdate,
  });

  final LfoSnapshot mod;
  final Future<void> Function(String param, double value) onUpdate;

  static const accent = Color(0xFFE8A54B);
  static const syncLabels = ['1/1', '1/2', '1/4', '1/8', '1/16'];

  bool get _isEnvelope => mod.modulatorType == ModulatorTypes.envelope;
  bool get _isSync => mod.retrigger == ModulatorTypes.retriggerSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isEnvelope) {
      return _envelopeLayout(theme);
    }
    if (mod.type == 'random_generator') return _randomGeneratorLayout(theme);
    return _lfoLayout(theme);
  }

  /// Envelope layout: header, expanded preview, then delay bar + knobs pinned to bottom.
  Widget _envelopeLayout(ThemeData theme) {
    return Container(
      color: const Color(0xFF14141C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

  /// LFO layout: header, Expanded preview, mode bar, polarity chips, knob row.
  Widget _lfoLayout(ThemeData theme) {
    return Container(
      color: const Color(0xFF14141C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

  /// Random Generator layout: header, retrigger bar, knobs row, polarity toggle.
  Widget _randomGeneratorLayout(ThemeData theme) {
    return Container(
      color: const Color(0xFF14141C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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

  /// Small 2-segment polarity toggle: ± and +.
  Widget _polarityToggle() {
    const accent = Color(0xFFE8A54B);
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

  Widget _rndKnob(String label, double value, ValueChanged<double> onChanged) {
    return Expanded(
      child: Center(
        child: RotaryKnob(
          label: label,
          value: value.clamp(0.0, 1.0),
          displayValue: value.toStringAsFixed(2),
          size: DeviceKnobSizes.compact,
          accentColor: const Color(0xFFE8A54B),
          onChanged: onChanged,
        ),
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

  /// Single row of knobs for envelope parameters, anchored to the bottom.
  Widget _envelopeKnobs() {
    final hasHold = mod.curveType == 3;     // AHDSR
    final hasSustain = mod.curveType != 2;  // not ADR
    final hasDecay = mod.curveType != 1;    // not ASR

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _envKnob('A', 'Attack', mod.attack),
        if (hasHold) _envKnob('H', 'Hold', mod.hold),
        if (hasDecay) _envKnob('D', 'Decay', mod.decay),
        if (hasSustain) _envKnob('S', 'Sustain', mod.sustain),
        _envKnob('R', 'Release', mod.release),
      ],
    );
  }

  Widget _envKnob(String short, String label, double value) {
    return Expanded(
      child: Center(
        child: RotaryKnob(
          label: short,
          value: value.clamp(0.0, 1.0),
          displayValue: ModulatorRateCodec.formatEnvelope(value),
          size: DeviceKnobSizes.compact,
          accentColor: accent,
          onChanged: (v) => onUpdate(label.toLowerCase(), v),
        ),
      ),
    );
  }

  // ===== LFO-specific helpers =====

  /// Retrigger mode — segmented button bar (like _PlaybackModeSegments).
  Widget _lfoSegmentBar() {
    const accent = Color(0xFFE8A54B);
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
    const accent = Color(0xFFE8A54B);
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

  /// 4-knob row: Rate, Phase, Warp, Spread
  Widget _lfoKnobs() {
    final effMorph = mod.analogMode != 0 ? 0.0 : mod.morph;
    final effSpread = mod.analogMode != 0 ? 0.5 : mod.spread;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _lfoKnob(
          ModulatorRateCodec.rateKnobLabel(mod),
          ModulatorRateCodec.formatRate(mod),
          mod.rate.clamp(0.0, 1.0),
          (v) => onUpdate('rate', v),
        ),
        _lfoKnob(
          'Ph',
          ModulatorRateCodec.formatPhase(mod.phase),
          mod.phase.clamp(0.0, 1.0),
          (v) => onUpdate('phase', v),
        ),
        _lfoKnob(
          'Wp',
          ModulatorRateCodec.formatMorph(effMorph),
          effMorph.clamp(0.0, 1.0),
          (v) => onUpdate('morph', v),
        ),
        _lfoKnob(
          'Sp',
          ModulatorRateCodec.formatSpread(effSpread),
          effSpread.clamp(0.0, 1.0),
          (v) => onUpdate('spread', v),
        ),
      ],
    );
  }

  Widget _lfoKnob(String label, String displayValue, double value, ValueChanged<double> onChanged) {
    return Expanded(
      child: Center(
        child: RotaryKnob(
          label: label,
          value: value,
          displayValue: displayValue,
          size: DeviceKnobSizes.compact,
          accentColor: const Color(0xFFE8A54B),
          onChanged: onChanged,
        ),
      ),
    );
  }
}