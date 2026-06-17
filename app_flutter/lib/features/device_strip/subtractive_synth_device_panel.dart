import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'subtractive_waveform_preview.dart';

enum SubtractivePanelDensity { strip, editor }

enum SubtractiveDeviceTab { osc, mix, filter, amp }

class SubtractiveSynthDevicePanel extends StatefulWidget {
  const SubtractiveSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = SubtractivePanelDensity.strip,
    this.embeddedInCard = false,
    this.selectedTab,
    this.onTabChanged,
    this.onOpenFullscreen,
    this.showExpandControl = false,
  });

  final DeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final SubtractivePanelDensity density;
  final bool embeddedInCard;
  final SubtractiveDeviceTab? selectedTab;
  final ValueChanged<SubtractiveDeviceTab>? onTabChanged;
  final VoidCallback? onOpenFullscreen;
  final bool showExpandControl;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = Color(0xFF7B6CF6);

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Osc', icon: Icons.waves),
    DeviceTabSpec(label: 'Mix', icon: Icons.blender),
    DeviceTabSpec(label: 'Filter', icon: Icons.tune),
    DeviceTabSpec(label: 'Amp', icon: Icons.show_chart),
  ];

  @override
  State<SubtractiveSynthDevicePanel> createState() => _SubtractiveSynthDevicePanelState();
}

class _SubtractiveSynthDevicePanelState extends State<SubtractiveSynthDevicePanel> {
  late SubtractiveDeviceTab _tab;

  SubtractiveDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _knobSize => widget.density == SubtractivePanelDensity.editor
      ? DeviceKnobSizes.editor
      : DeviceKnobSizes.strip;

  @override
  void initState() {
    super.initState();
    _tab = SubtractiveDeviceTab.osc;
  }

  @override
  void didUpdateWidget(covariant SubtractiveSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null && widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_activeTab) {
      SubtractiveDeviceTab.osc => _oscTab(),
      SubtractiveDeviceTab.mix => _mixTab(),
      SubtractiveDeviceTab.filter => _filterTab(),
      SubtractiveDeviceTab.amp => _ampTab(),
    };

    if (widget.embeddedInCard) {
      return body;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embeddedInCard)
          DeviceTabBar(
            tabs: SubtractiveSynthDevicePanel.containerTabs,
            selectedIndex: _activeTab.index,
            accentColor: SubtractiveSynthDevicePanel.accent,
            onSelected: (i) {
              final tab = SubtractiveDeviceTab.values[i];
              setState(() => _tab = tab);
              widget.onTabChanged?.call(tab);
            },
          ),
        Expanded(child: body),
      ],
    );
  }

  Widget _oscTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _oscBank('Osc 1', widget.device.osc1Wave, (w) {
            widget.onParameterChanged('osc1Wave', w.toDouble());
          }, widget.device.osc1Octave, widget.device.osc1Semi, widget.device.osc1Detune),
          const SizedBox(height: 8),
          _oscBank('Osc 2', widget.device.osc2Wave, (w) {
            widget.onParameterChanged('osc2Wave', w.toDouble());
          }, widget.device.osc2Octave, widget.device.osc2Semi, widget.device.osc2Detune),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RotaryKnob(
                  label: 'Unison',
                  value: widget.device.unisonVoices,
                  size: _knobSize * 0.85,
                  displayValue: '${1 + (widget.device.unisonVoices * 3).round()}',
                  onChanged: (v) => widget.onParameterChanged('unisonVoices', v),
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: 'Spread',
                  value: widget.device.unisonDetune,
                  size: _knobSize * 0.85,
                  displayValue: SamplerDevicePanel.formatPercent(widget.device.unisonDetune),
                  onChanged: (v) => widget.onParameterChanged('unisonDetune', v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _oscBank(
    String label,
    int wave,
    ValueChanged<int> onWave,
    double octave,
    double semi,
    double detune,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        SubtractiveWaveformPreview(wave: wave, accent: SubtractiveSynthDevicePanel.accent),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          children: List.generate(5, (i) {
            final selected = wave == i;
            return ChoiceChip(
              label: Text(['Sine', 'Tri', 'Saw', 'Sqr', 'Pls'][i],
                  style: TextStyle(fontSize: 10, color: selected ? Colors.black : Colors.white70)),
              selected: selected,
              selectedColor: SubtractiveSynthDevicePanel.accent,
              backgroundColor: const Color(0xFF2A2A34),
              onSelected: (_) => onWave(i),
              visualDensity: VisualDensity.compact,
            );
          }),
        ),
        Row(
          children: [
            Expanded(
              child: RotaryKnob(
                label: 'Oct',
                value: octave,
                size: _knobSize * 0.75,
                displayValue: '${((octave - 0.5) * 4).round()}',
                onChanged: (v) => widget.onParameterChanged(
                  label == 'Osc 1' ? 'osc1Octave' : 'osc2Octave',
                  v,
                ),
              ),
            ),
            Expanded(
              child: RotaryKnob(
                label: 'Semi',
                value: semi,
                size: _knobSize * 0.75,
                displayValue: '${(semi * 11).round()}',
                onChanged: (v) => widget.onParameterChanged(
                  label == 'Osc 1' ? 'osc1Semi' : 'osc2Semi',
                  v,
                ),
              ),
            ),
            Expanded(
              child: RotaryKnob(
                label: 'Fine',
                value: detune,
                size: _knobSize * 0.75,
                displayValue: '${((detune - 0.5) * 100).round()}',
                onChanged: (v) => widget.onParameterChanged(
                  label == 'Osc 1' ? 'osc1Detune' : 'osc2Detune',
                  v,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mixTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: RotaryKnob(
                  label: 'Osc 1',
                  value: widget.device.osc1Level,
                  size: _knobSize,
                  displayValue: SamplerDevicePanel.formatPercent(widget.device.osc1Level),
                  onChanged: (v) => widget.onParameterChanged('osc1Level', v),
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: 'Osc 2',
                  value: widget.device.osc2Level,
                  size: _knobSize,
                  displayValue: SamplerDevicePanel.formatPercent(widget.device.osc2Level),
                  onChanged: (v) => widget.onParameterChanged('osc2Level', v),
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: 'Noise',
                  value: widget.device.noiseLevel,
                  size: _knobSize,
                  displayValue: SamplerDevicePanel.formatPercent(widget.device.noiseLevel),
                  onChanged: (v) => widget.onParameterChanged('noiseLevel', v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Mix mode', style: Theme.of(context).textTheme.labelSmall),
          ),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(5, (i) {
              final selected = widget.device.oscMixMode == i;
              return ChoiceChip(
                label: Text(['Mix', 'Neg', 'AM', 'Sign', 'Max'][i],
                    style: TextStyle(fontSize: 10, color: selected ? Colors.black : Colors.white70)),
                selected: selected,
                selectedColor: SubtractiveSynthDevicePanel.accent,
                backgroundColor: const Color(0xFF2A2A34),
                onSelected: (_) => widget.onParameterChanged('oscMixMode', i.toDouble()),
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filterTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LP12 low-pass', style: TextStyle(color: Colors.white54, fontSize: 10)),
          Row(
            children: [
              Expanded(
                child: RotaryKnob(
                  label: 'Cutoff',
                  value: widget.device.filterCutoff,
                  size: _knobSize,
                  displayValue: SamplerDevicePanel.formatCutoffHz(widget.device.filterCutoff),
                  onChanged: (v) => widget.onParameterChanged('filterCutoff', v),
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: 'Res',
                  value: widget.device.filterQ,
                  size: _knobSize,
                  displayValue: SamplerDevicePanel.formatQ(widget.device.filterQ),
                  onChanged: (v) => widget.onParameterChanged('filterQ', v),
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: 'Env amt',
                  value: widget.device.filterEnvAmount,
                  size: _knobSize,
                  displayValue: SamplerDevicePanel.formatPercent(widget.device.filterEnvAmount),
                  onChanged: (v) => widget.onParameterChanged('filterEnvAmount', v),
                ),
              ),
            ],
          ),
          _adsrRow(
            attack: widget.device.filterAttack,
            decay: widget.device.filterDecay,
            sustain: widget.device.filterSustain,
            release: widget.device.filterRelease,
            onChanged: (id, v) => widget.onParameterChanged(id, v),
            prefix: 'filter',
          ),
        ],
      ),
    );
  }

  Widget _ampTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _adsrRow(
            attack: widget.device.attack,
            decay: widget.device.decay,
            sustain: widget.device.sustain,
            release: widget.device.release,
            onChanged: widget.onParameterChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RotaryKnob(
                  label: 'Glide',
                  value: widget.device.glideMs,
                  size: _knobSize * 0.9,
                  displayValue: widget.device.glideMs <= 0.001
                      ? 'Off'
                      : '${(widget.device.glideMs * 2000).round()} ms',
                  onChanged: (v) => widget.onParameterChanged('glideMs', v),
                ),
              ),
              Expanded(
                child: RotaryKnob(
                  label: 'Velocity',
                  value: widget.device.velocitySensitivity,
                  size: _knobSize * 0.9,
                  displayValue: SamplerDevicePanel.formatPercent(widget.device.velocitySensitivity),
                  onChanged: (v) => widget.onParameterChanged('velocitySensitivity', v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _adsrRow({
    required double attack,
    required double decay,
    required double sustain,
    required double release,
    required void Function(String id, double value) onChanged,
    String prefix = '',
  }) {
    String id(String name) => prefix.isEmpty ? name : '$prefix${name[0].toUpperCase()}${name.substring(1)}';
    return Row(
      children: [
        Expanded(
          child: RotaryKnob(
            label: 'A',
            value: attack,
            size: _knobSize * 0.8,
            displayValue: SamplerDevicePanel.formatPercent(attack),
            onChanged: (v) => onChanged(id('attack'), v),
          ),
        ),
        Expanded(
          child: RotaryKnob(
            label: 'D',
            value: decay,
            size: _knobSize * 0.8,
            displayValue: SamplerDevicePanel.formatPercent(decay),
            onChanged: (v) => onChanged(id('decay'), v),
          ),
        ),
        Expanded(
          child: RotaryKnob(
            label: 'S',
            value: sustain,
            size: _knobSize * 0.8,
            displayValue: SamplerDevicePanel.formatPercent(sustain),
            onChanged: (v) => onChanged(id('sustain'), v),
          ),
        ),
        Expanded(
          child: RotaryKnob(
            label: 'R',
            value: release,
            size: _knobSize * 0.8,
            displayValue: SamplerDevicePanel.formatPercent(release),
            onChanged: (v) => onChanged(id('release'), v),
          ),
        ),
      ],
    );
  }
}
