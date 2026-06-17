import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'draggable_int_value_box.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'subtractive_waveform_preview.dart';

enum SubtractivePanelDensity { strip, editor }

enum SubtractiveDeviceTab { osc, mix, filter, amp }

/// Visual variant for the panel container.
///
///   * [screen] — darkest fill, subtle border. Used for waveform/signal displays.
///   * [elevated] — medium-dark fill, subtle border. Used for inset knob-column panels.
///   * [subtle] — between elevated and flat. Used for envelope rows and grouping.
///   * [flat] — lightest fill, no border by default. Used for lightweight grouping.
enum PanelVariant { screen, elevated, subtle, flat }

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
  static const Color accent = DeviceStripTheme.subtractiveSynthAccent;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Osc', icon: Icons.waves),
    DeviceTabSpec(label: 'Mix', icon: Icons.blender),
    DeviceTabSpec(label: 'Filter', icon: Icons.tune),
    DeviceTabSpec(label: 'Amp', icon: Icons.show_chart),
  ];

  static const _mixModes = ['Mix', 'Neg', 'AM', 'Sign', 'Max'];
  static const _filterTypes = ['LP 12 dB'];

  @override
  State<SubtractiveSynthDevicePanel> createState() => _SubtractiveSynthDevicePanelState();
}

class _SubtractiveSynthDevicePanelState extends State<SubtractiveSynthDevicePanel> {
  late SubtractiveDeviceTab _tab;

  SubtractiveDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _knobSize => widget.density == SubtractivePanelDensity.editor
      ? DeviceKnobSizes.editor
      : DeviceKnobSizes.strip;

  Widget _knob({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    String? displayValue,
    double? size,
  }) {
    return RotaryKnob(
      label: label,
      value: value,
      onChanged: onChanged,
      displayValue: displayValue,
      size: size ?? _knobSize,
      accentColor: SubtractiveSynthDevicePanel.accent,
    );
  }

  Widget _panelBox({
    required Widget child,
    PanelVariant variant = PanelVariant.screen,
    bool showBorder = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(4),
  }) {
    final Color fill = switch (variant) {
      PanelVariant.screen => const Color(0xFF121218),
      PanelVariant.elevated => const Color(0xFF16161E),
      PanelVariant.subtle => const Color(0xFF181821),
      PanelVariant.flat => const Color(0xFF1A1A24),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
        border: showBorder
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }

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
    final bankWidth = _knobSize * 2.9;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: bankWidth,
            child: _oscBank(
              label: 'Osc 1',
              shape: widget.device.osc1Shape,
              shapeParam: 'osc1Shape',
              semi: widget.device.osc1Semi,
              semiParam: 'osc1Semi',
              octaveNorm: widget.device.osc1Octave,
              octaveParam: 'osc1Octave',
              sync: widget.device.osc1Sync,
              syncParam: 'osc1Sync',
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: bankWidth,
            child: _oscBank(
              label: 'Osc 2',
              shape: widget.device.osc2Shape,
              shapeParam: 'osc2Shape',
              semi: widget.device.osc2Semi,
              semiParam: 'osc2Semi',
              octaveNorm: widget.device.osc2Octave,
              octaveParam: 'osc2Octave',
              sync: widget.device.osc2Sync,
              syncParam: 'osc2Sync',
            ),
          ),
        ],
      ),
    );
  }

  Widget _oscBank({
    required String label,
    required double shape,
    required String shapeParam,
    required double semi,
    required String semiParam,
    required double octaveNorm,
    required String octaveParam,
    required double sync,
    required String syncParam,
  }) {
    final octave = subtractiveOctaveFromNorm(octaveNorm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Expanded(
          child: _panelBox(
              variant: PanelVariant.screen,
              child: SubtractiveWaveformPreview(
              shape: shape,
              accent: SubtractiveSynthDevicePanel.accent,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _knob(
              label: 'Shape',
              value: shape,
              size: _knobSize * 0.82,
              displayValue: subtractiveShapeLabel(shape),
              onChanged: (v) => widget.onParameterChanged(shapeParam, v),
            ),
            _knob(
              label: 'Pitch',
              value: semi,
              size: _knobSize * 0.82,
              displayValue: '${(semi * 11).round()}',
              onChanged: (v) => widget.onParameterChanged(semiParam, v),
            ),
            _knob(
              label: 'Sync',
              value: sync,
              size: _knobSize * 0.82,
              displayValue: SamplerDevicePanel.formatPercent(sync),
              onChanged: (v) => widget.onParameterChanged(syncParam, v),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: DraggableIntValueBox(
            value: octave,
            accentColor: SubtractiveSynthDevicePanel.accent,
            onChanged: (v) => widget.onParameterChanged(
              octaveParam,
              subtractiveNormFromOctave(v),
            ),
          ),
        ),
      ],
    );
  }

Widget _mixTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Left Group: Unison + Spread (Vertical Column, Shrunk and Aligned Left)
          SizedBox(
            width: _knobSize + 24,
            child: _panelBox(
              variant: PanelVariant.elevated,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'UNISON',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _knob(
                          label: 'Voices',
                          value: widget.device.unisonVoices,
                          size: _knobSize * 0.82,
                          displayValue: '${1 + (widget.device.unisonVoices * 3).round()}',
                          onChanged: (v) => widget.onParameterChanged('unisonVoices', v),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _knob(
                          label: 'Spread',
                          value: widget.device.unisonDetune,
                          size: _knobSize * 0.82,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.unisonDetune),
                          onChanged: (v) => widget.onParameterChanged('unisonDetune', v),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ),
            ),
          ),
          const SizedBox(width: 8),
          // Right Group: Mix Mode + Mix + Noise (Vertical Column, Shrunk and Aligned Left)
          SizedBox(
            width: _knobSize + 24,
            child: _panelBox(
              variant: PanelVariant.elevated,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'MIXER',
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: _knobSize + 4,
                          height: 24,
                          child: _borderlessDropdown<int>(
                            value: widget.device.oscMixMode.clamp(0, SubtractiveSynthDevicePanel._mixModes.length - 1),
                            items: List.generate(
                              SubtractiveSynthDevicePanel._mixModes.length,
                              (i) => DropdownMenuItem(
                                value: i,
                                child: Text(SubtractiveSynthDevicePanel._mixModes[i]),
                              ),
                            ),
                            onChanged: (v) {
                              if (v != null) widget.onParameterChanged('oscMixMode', v.toDouble());
                            },
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _knob(
                          label: 'Mix',
                          value: widget.device.oscMix,
                          size: _knobSize * 0.82,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.oscMix),
                          onChanged: (v) => widget.onParameterChanged('oscMix', v),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _knob(
                          label: 'Noise',
                          value: widget.device.noiseLevel,
                          size: _knobSize * 0.82,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.noiseLevel),
                          onChanged: (v) => widget.onParameterChanged('noiseLevel', v),
                        ),
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab() {
    final mode = widget.device.filterMode.clamp(0, SubtractiveSynthDevicePanel._filterTypes.length - 1);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelBox(
            variant: PanelVariant.elevated,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FILTER',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      width: _knobSize + 24,
                      height: 24,
                      child: _borderlessDropdown<int>(
                        value: mode,
                        items: List.generate(
                          SubtractiveSynthDevicePanel._filterTypes.length,
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(SubtractiveSynthDevicePanel._filterTypes[i]),
                          ),
                        ),
                        onChanged: (v) {
                          if (v != null) widget.onParameterChanged('filterMode', v.toDouble());
                        },
                      ),
                    ),
                    const Spacer(),
                    _knob(
                      label: 'Cutoff',
                      value: widget.device.filterCutoff,
                      displayValue: SamplerDevicePanel.formatCutoffHz(widget.device.filterCutoff),
                      onChanged: (v) => widget.onParameterChanged('filterCutoff', v),
                    ),
                    const SizedBox(width: 4),
                    _knob(
                      label: 'Res',
                      value: widget.device.filterQ,
                      displayValue: SamplerDevicePanel.formatQ(widget.device.filterQ),
                      onChanged: (v) => widget.onParameterChanged('filterQ', v),
                    ),
                    const SizedBox(width: 4),
                    _knob(
                      label: 'Env amt',
                      value: widget.device.filterEnvAmount,
                      displayValue: SamplerDevicePanel.formatPercent(widget.device.filterEnvAmount),
                      onChanged: (v) => widget.onParameterChanged('filterEnvAmount', v),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          _panelBox(
            variant: PanelVariant.subtle,
            showBorder: false,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _adsrRow(
              attack: widget.device.filterAttack,
              decay: widget.device.filterDecay,
              sustain: widget.device.filterSustain,
              release: widget.device.filterRelease,
              onChanged: (id, v) => widget.onParameterChanged(id, v),
              prefix: 'filter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _borderlessDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF1C1C24),
        style: const TextStyle(
          color: SubtractiveSynthDevicePanel.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        icon: const Icon(Icons.expand_more, color: SubtractiveSynthDevicePanel.accent, size: 14),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _ampTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panelBox(
            variant: PanelVariant.elevated,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AMP',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _knob(
                      label: 'Glide',
                      value: widget.device.glideMs,
                      size: _knobSize * 0.9,
                      displayValue: widget.device.glideMs <= 0.001
                          ? 'Off'
                          : '${(widget.device.glideMs * 2000).round()} ms',
                      onChanged: (v) => widget.onParameterChanged('glideMs', v),
                    ),
                    const SizedBox(width: 8),
                    _knob(
                      label: 'Velocity',
                      value: widget.device.velocitySensitivity,
                      size: _knobSize * 0.9,
                      displayValue: SamplerDevicePanel.formatPercent(widget.device.velocitySensitivity),
                      onChanged: (v) => widget.onParameterChanged('velocitySensitivity', v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          _panelBox(
            variant: PanelVariant.subtle,
            showBorder: false,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _adsrRow(
              attack: widget.device.attack,
              decay: widget.device.decay,
              sustain: widget.device.sustain,
              release: widget.device.release,
              onChanged: widget.onParameterChanged,
            ),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _knob(label: 'A', value: attack, size: _knobSize * 0.8,
          displayValue: SamplerDevicePanel.formatPercent(attack),
          onChanged: (v) => onChanged(id('attack'), v)),
        _knob(label: 'D', value: decay, size: _knobSize * 0.8,
          displayValue: SamplerDevicePanel.formatPercent(decay),
          onChanged: (v) => onChanged(id('decay'), v)),
        _knob(label: 'S', value: sustain, size: _knobSize * 0.8,
          displayValue: SamplerDevicePanel.formatPercent(sustain),
          onChanged: (v) => onChanged(id('sustain'), v)),
        _knob(label: 'R', value: release, size: _knobSize * 0.8,
          displayValue: SamplerDevicePanel.formatPercent(release),
          onChanged: (v) => onChanged(id('release'), v)),
      ],
    );
  }
}

