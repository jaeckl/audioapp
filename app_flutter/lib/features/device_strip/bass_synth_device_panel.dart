import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_automation_spinner.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'draggable_int_value_box.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';

enum BassPanelDensity { strip, editor }

enum BassSynthDeviceTab { tone, filter, character }

class BassSynthDevicePanel extends StatefulWidget {
  const BassSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = BassPanelDensity.strip,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final BassPanelDensity density;
  final BassSynthDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color accent = DeviceStripTheme.bassSynthAccent;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'TONE', icon: Icons.tune),
    DeviceTabSpec(label: 'FILTER', icon: Icons.filter_alt),
    DeviceTabSpec(label: 'CHAR', icon: Icons.graphic_eq),
  ];

  static String subOctaveLabel(int value) {
    return switch (value) {
      0 => '-1',
      1 => '-2',
      2 => '-3',
      _ => '$value',
    };
  }

  static String bassOctaveLabel(int value) {
    return switch (value) {
      0 => '-4',
      1 => '-3',
      2 => '-2',
      3 => '-1',
      4 => '0',
      _ => '$value',
    };
  }

  @override
  State<BassSynthDevicePanel> createState() => _BassSynthDevicePanelState();
}

class _BassSynthDevicePanelState extends State<BassSynthDevicePanel> {
  late BassSynthDeviceTab _tab;

  BassSynthDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _knobSize => widget.density == BassPanelDensity.editor
      ? DeviceKnobSizes.editor
      : DeviceKnobSizes.strip;

  Widget _knob({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    String? displayValue,
    double? size,
    String? paramId,
    Map<String, double> modulationAmounts = const {},
    int? connectModeLfoId,
    void Function(String paramId, double amount)? onModulationAssign,
    double labelGap = 3,
  }) {
    final modAmount = paramId != null ? modulationAmounts[paramId] ?? 0.0 : 0.0;
    return RotaryKnob(
      label: label,
      value: value,
      onChanged: onChanged,
      displayValue: displayValue,
      size: size ?? _knobSize,
      labelGap: labelGap,
      accentColor: BassSynthDevicePanel.accent,
      modulationActive: paramId != null && widget.modulatedParams.contains(paramId),
      automationActive: paramId != null && widget.automatedParams.contains(paramId),
      modulationAmount: modAmount,
      connectModeActive: paramId != null && connectModeLfoId != null,
      onModulationAssign: paramId != null && onModulationAssign != null
          ? (a) => onModulationAssign(paramId, a)
          : null,
      linkModeActive: paramId != null && widget.automationLinkActive,
      linkModeAccent: const Color(0xFFB48CFF),
      onLinkTap: paramId != null && widget.onAutomationLinkTap != null
          ? () => widget.onAutomationLinkTap!(paramId)
          : null,
      onAutomateRequest: paramId != null && widget.onAutomateParameter != null
          ? () => widget.onAutomateParameter!(paramId)
          : null,
    );
  }

  Widget _panelBox({
    required Widget child,
    Color color = const Color(0xFF121218),
    bool showBorder = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(4),
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
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
    _tab = BassSynthDeviceTab.tone;
  }

  @override
  void didUpdateWidget(covariant BassSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null && widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildTabContent();
    return body;
  }

  Widget _buildTabContent() {
    return switch (_activeTab) {
      BassSynthDeviceTab.tone => _toneTab(),
      BassSynthDeviceTab.filter => _filterTab(),
      BassSynthDeviceTab.character => _charTab(),
    };
  }

  Widget _toneTab() {
    final kSize = _knobSize;
    final smallKnob = kSize * 0.72;
    // Single row of 5 controls: morph · sub mix · sub oct · oct · noise
    // ADSR compact row beneath.
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'Morph',
                    value: widget.device.bassOscShape,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.bassOscShape),
                    onChanged: (v) => widget.onParameterChanged('bassOscShape', v),
                    paramId: 'bassOscShape',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Sub Mix',
                    value: widget.device.bassSubMix,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.bassSubMix),
                    onChanged: (v) => widget.onParameterChanged('bassSubMix', v),
                    paramId: 'bassSubMix',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _intOctaveSlot(
                    value: widget.device.bassSubOctave,
                    paramId: 'bassSubOctave',
                    min: 0,
                    max: 2,
                    label: 'Sub Oct',
                    formatter: BassSynthDevicePanel.subOctaveLabel,
                  ),
                  _intOctaveSlot(
                    value: widget.device.bassOctave,
                    paramId: 'bassOctave',
                    min: 0,
                    max: 4,
                    label: 'Oct',
                    formatter: BassSynthDevicePanel.bassOctaveLabel,
                  ),
                  _knob(
                    label: 'Noise',
                    value: widget.device.bassNoise,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.bassNoise),
                    onChanged: (v) => widget.onParameterChanged('bassNoise', v),
                    paramId: 'bassNoise',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'A',
                    value: widget.device.attack,
                    size: smallKnob,
                    labelGap: 0,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.attack),
                    onChanged: (v) => widget.onParameterChanged('attack', v),
                    paramId: 'attack',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'S',
                    value: widget.device.sustain,
                    size: smallKnob,
                    labelGap: 0,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.sustain),
                    onChanged: (v) => widget.onParameterChanged('sustain', v),
                    paramId: 'sustain',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'R',
                    value: widget.device.release,
                    size: smallKnob,
                    labelGap: 0,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.release),
                    onChanged: (v) => widget.onParameterChanged('release', v),
                    paramId: 'release',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _intOctaveSlot({
    required int value,
    required String paramId,
    required int min,
    required int max,
    required String label,
    required String Function(int) formatter,
  }) {
    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DraggableIntValueBox(
          value: value,
          showLabel: false,
          accentColor: BassSynthDevicePanel.accent,
          onChanged: (v) => widget.onParameterChanged(paramId, v.toDouble()),
          min: min,
          max: max,
          label: label,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    return deviceAutomationSpinner(
      paramId: paramId,
      width: 46,
      height: 52,
      accentColor: BassSynthDevicePanel.accent,
      borderAlpha: 0.5,
      child: inner,
      modulatedParams: widget.modulatedParams,
      automatedParams: widget.automatedParams,
      modulationAmounts: widget.modulationAmounts,
      connectModeLfoId: widget.connectModeLfoId,
      onModulationAssign: widget.onModulationAssign,
      automationLinkActive: widget.automationLinkActive,
      onAutomationLinkTap: widget.onAutomationLinkTap,
      onAutomateParameter: widget.onAutomateParameter,
    );
  }

  Widget _filterTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'Cutoff',
                    value: widget.device.filterCutoff,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatCutoffHz(widget.device.filterCutoff),
                    onChanged: (v) => widget.onParameterChanged('filterCutoff', v),
                    paramId: 'filterCutoff',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Res',
                    value: widget.device.bassFilterResonance,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatQ(widget.device.bassFilterResonance),
                    onChanged: (v) => widget.onParameterChanged('bassFilterResonance', v),
                    paramId: 'bassFilterResonance',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Env Amt',
                    value: widget.device.filterEnvAmount,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.filterEnvAmount),
                    onChanged: (v) => widget.onParameterChanged('filterEnvAmount', v),
                    paramId: 'filterEnvAmount',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Decay',
                    value: widget.device.filterDecay,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.filterDecay),
                    onChanged: (v) => widget.onParameterChanged('filterDecay', v),
                    paramId: 'filterDecay',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _charTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'Drive',
                    value: widget.device.bassDrive,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.bassDrive),
                    onChanged: (v) => widget.onParameterChanged('bassDrive', v),
                    paramId: 'bassDrive',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Squash',
                    value: widget.device.bassSquash,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.bassSquash),
                    onChanged: (v) => widget.onParameterChanged('bassSquash', v),
                    paramId: 'bassSquash',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Glide',
                    value: widget.device.glideMs,
                    size: kSize,
                    displayValue: widget.device.glideMs <= 0.001
                        ? 'Off'
                        : '${(widget.device.glideMs * 2000).round()} ms',
                    onChanged: (v) => widget.onParameterChanged('glideMs', v),
                    paramId: 'glideMs',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Vel',
                    value: widget.device.bassVelocitySense,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.bassVelocitySense),
                    onChanged: (v) => widget.onParameterChanged('bassVelocitySense', v),
                    paramId: 'bassVelocitySense',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}