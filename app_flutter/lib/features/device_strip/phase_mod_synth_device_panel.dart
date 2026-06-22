import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';
import 'value_drag_box.dart';
import 'sampler_device_panel.dart';

enum PhaseModSynthPanelDensity { strip, editor }

enum PhaseModSynthDeviceTab { mix, op, tone }

class PhaseModSynthDevicePanel extends StatefulWidget {
  const PhaseModSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = PhaseModSynthPanelDensity.strip,
    this.selectedTab,
    this.onTabChanged,
    this.onOpenFullscreen,
    this.showExpandControl = false,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final PhaseModSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final PhaseModSynthPanelDensity density;
  final PhaseModSynthDeviceTab? selectedTab;
  final ValueChanged<PhaseModSynthDeviceTab>? onTabChanged;
  final VoidCallback? onOpenFullscreen;
  final bool showExpandControl;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color accent = DeviceStripTheme.phaseModSynthAccent;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'MIX', icon: Icons.blender),
    DeviceTabSpec(label: 'OP', icon: Icons.tune),
    DeviceTabSpec(label: 'TONE', icon: Icons.filter_alt),
  ];

  static const _ratioValues = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0];

  static int ratioNormToIndex(double norm) {
    return (norm * 8).round().clamp(0, 8);
  }

  static double indexToRatioNorm(int index) {
    return index / 8.0;
  }

  static String ratioDisplay(double norm) {
    final idx = ratioNormToIndex(norm);
    return '${_ratioValues[idx]}';
  }

  static String waveformDisplay(double value) {
    final idx = (value * 4).round().clamp(0, 4);
    return const ['Sine', 'Tri', 'Saw', 'Sq', 'Noise'][idx];
  }

  static String filterModeDisplay(int mode) {
    return const ['LP24', 'LP12', 'BP12', 'HP12', 'HP24', 'LP6'][mode.clamp(0, 5)];
  }

  @override
  State<PhaseModSynthDevicePanel> createState() => _PhaseModSynthDevicePanelState();
}

class _PhaseModSynthDevicePanelState extends State<PhaseModSynthDevicePanel> {
  late PhaseModSynthDeviceTab _tab;
  int _selectedOperator = 0;

  PhaseModSynthDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  // Scaled down knob sizes with ample breathing room to prevent touching borders
  double get _knobSize => widget.density == PhaseModSynthPanelDensity.editor
      ? DeviceKnobSizes.editor * 0.9
      : 40.0; // standard scaled down size

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
    double labelGap = 0, // decreased label gap to prevent touching container borders
  }) {
    final modAmount = paramId != null ? modulationAmounts[paramId] ?? 0.0 : 0.0;
    return RotaryKnob(
      label: label,
      value: value,
      onChanged: onChanged,
      displayValue: displayValue,
      size: size ?? _knobSize,
      labelGap: labelGap,
      accentColor: PhaseModSynthDevicePanel.accent,
      modulationActive: paramId != null && widget.modulatedParams.contains(paramId),
      automationActive: paramId != null && widget.automatedParams.contains(paramId),
      modulationAmount: modAmount,
      connectModeActive: paramId != null && connectModeLfoId != null,
      onModulationAssign: paramId != null && onModulationAssign != null
          ? (a) => onModulationAssign(paramId, a)
          : null,
      linkModeActive: paramId != null && widget.automationLinkActive,
      linkModeAccent: PhaseModSynthDevicePanel.accent,
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
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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

  Widget _toggleKnob({
    required String label,
    required double value,
    required String paramId,
    required String onLabel,
    required String offLabel,
  }) {
    final isOn = value >= 0.5;
    final size = _knobSize * 0.95;
    return GestureDetector(
      onTap: () => widget.onParameterChanged(paramId, isOn ? 0.0 : 1.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isOn
              ? PhaseModSynthDevicePanel.accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOn
                ? PhaseModSynthDevicePanel.accent.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isOn ? onLabel : offLabel,
              style: TextStyle(
                color: isOn ? PhaseModSynthDevicePanel.accent : Colors.white54,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 7.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _borderlessDropdown<T>({
    required T value,
    required List<T> items,
    required List<String> itemLabels,
    required ValueChanged<T> onChanged,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 24,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              dropdownColor: const Color(0xFF1C1C24),
              style: const TextStyle(
                color: PhaseModSynthDevicePanel.accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
              icon: const Icon(Icons.expand_more, color: PhaseModSynthDevicePanel.accent, size: 12),
              items: List.generate(items.length, (i) {
                return DropdownMenuItem<T>(
                  value: items[i],
                  child: Text(itemLabels[i], style: const TextStyle(fontSize: 10.5)),
                );
              }),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _draggableRatioBox({
    required int opIndex,
    required double value,
    required String paramId,
    required ValueChanged<double> onChanged,
  }) {
    // Uses the shared ValueDragBox widget — see value_drag_box.dart.
    return ValueDragBox(
      valueNorm: value,
      values: PhaseModSynthDevicePanel._ratioValues,
      format: (n) => PhaseModSynthDevicePanel.ratioDisplay(n),
      accent: PhaseModSynthDevicePanel.accent,
      paramId: paramId,
      modulatedParams: widget.modulatedParams,
      automatedParams: widget.automatedParams,
      modulationAmounts: widget.modulationAmounts,
      connectModeLfoId: widget.connectModeLfoId,
      onModulationAssign: widget.onModulationAssign,
      automationLinkActive: widget.automationLinkActive,
      onAutomationLinkTap: widget.onAutomationLinkTap,
      onAutomateParameter: widget.onAutomateParameter,
      onChanged: onChanged,
      resetIndex: 1, // 1.0 ratio
      dragPixelsPerStep: 12,
      footerLabel: 'Ratio',
    );
  }

  Widget _adsrRow({
    required String prefix,
    required double a,
    required double d,
    required double s,
    required double r,
  }) {
    final kSize = _knobSize;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _knob(
          label: 'A',
          value: a,
          size: kSize,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(a),
          onChanged: (v) => widget.onParameterChanged('${prefix}Attack', v),
          paramId: '${prefix}Attack',
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'D',
          value: d,
          size: kSize,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(d),
          onChanged: (v) => widget.onParameterChanged('${prefix}Decay', v),
          paramId: '${prefix}Decay',
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'S',
          value: s,
          size: kSize,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(s),
          onChanged: (v) => widget.onParameterChanged('${prefix}Sustain', v),
          paramId: '${prefix}Sustain',
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'R',
          value: r,
          size: kSize,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(r),
          onChanged: (v) => widget.onParameterChanged('${prefix}Release', v),
          paramId: '${prefix}Release',
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
      ],
    );
  }

  double _opParam(int opIndex, String param) {
    switch (opIndex) {
      case 0:
        return switch (param) {
          'ratio' => widget.device.pmOp1Ratio,
          'fine' => widget.device.pmOp1Fine,
          'level' => widget.device.pmOp1Level,
          'wave' => widget.device.pmOp1Wave,
          'attack' => widget.device.pmOp1Attack,
          'decay' => widget.device.pmOp1Decay,
          'sustain' => widget.device.pmOp1Sustain,
          'release' => widget.device.pmOp1Release,
          'velSense' => widget.device.pmOp1VelSense,
          'keyTrack' => widget.device.pmOp1KeyTrack,
          _ => 0.0,
        };
      case 1:
        return switch (param) {
          'ratio' => widget.device.pmOp2Ratio,
          'fine' => widget.device.pmOp2Fine,
          'level' => widget.device.pmOp2Level,
          'wave' => widget.device.pmOp2Wave,
          'attack' => widget.device.pmOp2Attack,
          'decay' => widget.device.pmOp2Decay,
          'sustain' => widget.device.pmOp2Sustain,
          'release' => widget.device.pmOp2Release,
          'velSense' => widget.device.pmOp2VelSense,
          'keyTrack' => widget.device.pmOp2KeyTrack,
          _ => 0.0,
        };
      case 2:
        return switch (param) {
          'ratio' => widget.device.pmOp3Ratio,
          'fine' => widget.device.pmOp3Fine,
          'level' => widget.device.pmOp3Level,
          'wave' => widget.device.pmOp3Wave,
          'attack' => widget.device.pmOp3Attack,
          'decay' => widget.device.pmOp3Decay,
          'sustain' => widget.device.pmOp3Sustain,
          'release' => widget.device.pmOp3Release,
          'velSense' => widget.device.pmOp3VelSense,
          'keyTrack' => widget.device.pmOp3KeyTrack,
          _ => 0.0,
        };
      case 3:
        return switch (param) {
          'ratio' => widget.device.pmOp4Ratio,
          'fine' => widget.device.pmOp4Fine,
          'level' => widget.device.pmOp4Level,
          'wave' => widget.device.pmOp4Wave,
          'attack' => widget.device.pmOp4Attack,
          'decay' => widget.device.pmOp4Decay,
          'sustain' => widget.device.pmOp4Sustain,
          'release' => widget.device.pmOp4Release,
          'velSense' => widget.device.pmOp4VelSense,
          'keyTrack' => widget.device.pmOp4KeyTrack,
          _ => 0.0,
        };
      default:
        return 0.0;
    }
  }

  String _opParamId(int opIndex, String param) {
    return 'pmOp${opIndex + 1}$param';
  }

  @override
  void initState() {
    super.initState();
    _tab = PhaseModSynthDeviceTab.mix;
  }

  @override
  void didUpdateWidget(covariant PhaseModSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null && widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildTabContent();
    if (widget.density == PhaseModSynthPanelDensity.editor) {
      return Column(
        children: [
          DeviceTabBar(
            tabs: PhaseModSynthDevicePanel.containerTabs,
            selectedIndex: _activeTab.index,
            accentColor: PhaseModSynthDevicePanel.accent,
            onSelected: (i) {
              final tab = PhaseModSynthDeviceTab.values[i];
              widget.onTabChanged?.call(tab);
              setState(() => _tab = tab);
            },
          ),
          Expanded(child: body),
        ],
      );
    }
    return body;
  }

  Widget _buildTabContent() {
    return switch (_activeTab) {
      PhaseModSynthDeviceTab.mix => _mixTab(),
      PhaseModSynthDeviceTab.op => _opTab(),
      PhaseModSynthDeviceTab.tone => _toneTab(),
    };
  }

  // ── MIX tab ──────────────────────────────────────────────────────────

  Widget _mixTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Master Amp ADSR Envelope
          Expanded(
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Amp Env (Master)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  _adsrRow(
                    prefix: '',
                    a: widget.device.attack,
                    d: widget.device.decay,
                    s: widget.device.sustain,
                    r: widget.device.release,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Row 2: Global Performance (Unison, Spread, Glide, Mono, Legato)
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'Unison',
                    value: widget.device.pmUnisonVoices,
                    size: kSize,
                    displayValue: '${(widget.device.pmUnisonVoices * 4).round() + 1}',
                    onChanged: (v) => widget.onParameterChanged('pmUnisonVoices', v),
                    paramId: 'pmUnisonVoices',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Spread',
                    value: widget.device.pmUnisonDetune,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.pmUnisonDetune),
                    onChanged: (v) => widget.onParameterChanged('pmUnisonDetune', v),
                    paramId: 'pmUnisonDetune',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Glide',
                    value: widget.device.pmGlide,
                    size: kSize,
                    displayValue: widget.device.pmGlide <= 0.001
                        ? 'Off'
                        : '${(widget.device.pmGlide * 2000).round()} ms',
                    onChanged: (v) => widget.onParameterChanged('pmGlide', v),
                    paramId: 'pmGlide',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleKnob(
                        label: '',
                        value: widget.device.pmMono,
                        paramId: 'pmMono',
                        onLabel: 'MONO',
                        offLabel: 'POLY',
                      ),
                      const SizedBox(width: 4),
                      _toggleKnob(
                        label: '',
                        value: widget.device.pmLegato,
                        paramId: 'pmLegato',
                        onLabel: 'LEG',
                        offLabel: 'NORM',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── OP tab ────────────────────────────────────────────────────────────

  Widget _opTab() {
    final kSize = _knobSize;
    final accent = PhaseModSynthDevicePanel.accent;
    final op = _selectedOperator;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: OP selector, Waveform, Level
          Expanded(
            flex: 6,
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  // OP Buttons
                  Expanded(
                    flex: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) {
                        final selected = op == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedOperator = i),
                          child: Container(
                            width: 32,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selected
                                  ? accent.withValues(alpha: 0.28)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: selected
                                    ? accent.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'OP${i + 1}',
                                style: TextStyle(
                                  color: selected ? accent : Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white10, width: 12),
                  // Waveform dropdown
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: _borderlessDropdown<double>(
                        label: 'Wave',
                        value: _opParam(op, 'wave'),
                        items: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        itemLabels: const ['Sine', 'Tri', 'Saw', 'Sq', 'Noise'],
                        onChanged: (v) => widget.onParameterChanged(
                          _opParamId(op, 'Wave'),
                          v,
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white10, width: 12),
                  // Level (Output mix / modulator strength of this operator)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: _knob(
                        label: 'Level',
                        value: _opParam(op, 'level'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'level')),
                        onChanged: (v) => widget.onParameterChanged(
                          _opParamId(op, 'Level'),
                          v,
                        ),
                        paramId: _opParamId(op, 'Level'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Row 2: Ratio, Fine, VelSense, KeyTrack
          Expanded(
            flex: 6,
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _draggableRatioBox(
                    opIndex: op,
                    value: _opParam(op, 'ratio'),
                    paramId: _opParamId(op, 'Ratio'),
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'Ratio'),
                      v,
                    ),
                  ),
                  _knob(
                    label: 'Fine',
                    value: _opParam(op, 'fine'),
                    size: kSize,
                    labelGap: 0,
                    displayValue: '${((_opParam(op, 'fine') - 0.5) * 100).round()} ct',
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'Fine'),
                      v,
                    ),
                    paramId: _opParamId(op, 'Fine'),
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Vel Sense',
                    value: _opParam(op, 'velSense'),
                    size: kSize,
                    labelGap: 0,
                    displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'velSense')),
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'VelSense'),
                      v,
                    ),
                    paramId: _opParamId(op, 'VelSense'),
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Key Track',
                    value: _opParam(op, 'keyTrack'),
                    size: kSize,
                    labelGap: 0,
                    displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'keyTrack')),
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'KeyTrack'),
                      v,
                    ),
                    paramId: _opParamId(op, 'KeyTrack'),
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Row 3: Unique Destination Influence Matrix (in place of ADSR matrix!)
          Expanded(
            flex: 7,
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OP${op + 1} Phase Modulation Drives',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _knob(
                        label: 'to OP1',
                        value: _opParam(op, 'attack'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'attack')),
                        onChanged: (v) => widget.onParameterChanged(_opParamId(op, 'Attack'), v),
                        paramId: _opParamId(op, 'Attack'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'to OP2',
                        value: _opParam(op, 'decay'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'decay')),
                        onChanged: (v) => widget.onParameterChanged(_opParamId(op, 'Decay'), v),
                        paramId: _opParamId(op, 'Decay'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'to OP3',
                        value: _opParam(op, 'sustain'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'sustain')),
                        onChanged: (v) => widget.onParameterChanged(_opParamId(op, 'Sustain'), v),
                        paramId: _opParamId(op, 'Sustain'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'to OP4',
                        value: _opParam(op, 'release'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'release')),
                        onChanged: (v) => widget.onParameterChanged(_opParamId(op, 'Release'), v),
                        paramId: _opParamId(op, 'Release'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TONE tab ──────────────────────────────────────────────────────────

  Widget _toneTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Filter Core
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: PhaseModFilterModeBar(
                        selectedIndex: widget.device.filterMode.clamp(0, 5),
                        accentColor: PhaseModSynthDevicePanel.accent,
                        onSelected: (mode) => widget.onParameterChanged('filterMode', mode.toDouble()),
                      ),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white10, width: 12),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: _knob(
                        label: 'Cutoff',
                        value: widget.device.filterCutoff,
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatCutoffHz(widget.device.filterCutoff),
                        onChanged: (v) => widget.onParameterChanged('filterCutoff', v),
                        paramId: 'filterCutoff',
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: _knob(
                        label: 'Res',
                        value: widget.device.filterQ,
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatQ(widget.device.filterQ),
                        onChanged: (v) => widget.onParameterChanged('filterQ', v),
                        paramId: 'filterQ',
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: _knob(
                        label: 'Env Amt',
                        value: widget.device.filterEnvAmount,
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(widget.device.filterEnvAmount),
                        onChanged: (v) => widget.onParameterChanged('filterEnvAmount', v),
                        paramId: 'filterEnvAmount',
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Row 2: Filter Envelope ADSR (with clear labeling!)
          Expanded(
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Filter Env',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  _adsrRow(
                    prefix: 'filter',
                    a: widget.device.filterAttack,
                    d: widget.device.filterDecay,
                    s: widget.device.filterSustain,
                    r: widget.device.filterRelease,
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

// ── CUSTOM FILTER MODE GRID ──────────────────────────────────────────────────

class PhaseModFilterModeBar extends StatelessWidget {
  const PhaseModFilterModeBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.accentColor,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            PhaseModFilterModeButton(
              index: 0,
              label: 'LP24',
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
              accentColor: accentColor,
            ),
            PhaseModFilterModeButton(
              index: 1,
              label: 'LP12',
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
              accentColor: accentColor,
            ),
            PhaseModFilterModeButton(
              index: 5,
              label: 'LP6',
              selected: selectedIndex == 5,
              onTap: () => onSelected(5),
              accentColor: accentColor,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            PhaseModFilterModeButton(
              index: 4,
              label: 'HP24',
              selected: selectedIndex == 4,
              onTap: () => onSelected(4),
              accentColor: accentColor,
            ),
            PhaseModFilterModeButton(
              index: 3,
              label: 'HP12',
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
              accentColor: accentColor,
            ),
            PhaseModFilterModeButton(
              index: 2,
              label: 'BP12',
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
              accentColor: accentColor,
            ),
          ],
        ),
      ],
    );
  }
}

class PhaseModFilterModeButton extends StatelessWidget {
  const PhaseModFilterModeButton({
    super.key,
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    this.size = 20, // slightly smaller icon paint for breathing room
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? accentColor : Colors.white.withValues(alpha: 0.35);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 28,
        decoration: BoxDecoration(
          color: selected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? accentColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size * 0.45,
              child: CustomPaint(
                painter: _PmFilterCurvePainter(
                  index: index,
                  color: fg,
                  strokeWidth: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: selected ? accentColor : Colors.white54,
                fontSize: 7.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PmFilterCurvePainter extends CustomPainter {
  _PmFilterCurvePainter({
    required this.index,
    required this.color,
    this.strokeWidth = 1.5,
  });

  final int index;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 1.5;
    final left = pad;
    final right = size.width - pad;
    final top = pad;
    final bottom = size.height - pad;
    final midX = (left + right) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    switch (index) {
      case 0: // LP24 (Steep LP)
        path.moveTo(left, top + 1);
        path.lineTo(midX - 3, top + 1);
        path.quadraticBezierTo(midX + 2, top + 1, right, bottom);
        break;
      case 1: // LP12 (Medium LP)
        path.moveTo(left, top + 1);
        path.lineTo(midX - 2, top + 1);
        path.quadraticBezierTo(right - 2, top + 2, right, bottom);
        break;
      case 5: // LP6 (Gentle LP)
        path.moveTo(left, top + 1);
        path.lineTo(midX - 2, top + 2);
        path.lineTo(right, bottom - 3);
        break;
      case 4: // HP24 (Steep HP)
        path.moveTo(left, bottom);
        path.quadraticBezierTo(midX - 2, top + 1, midX + 3, top + 1);
        path.lineTo(right, top + 1);
        break;
      case 3: // HP12 (Medium HP)
        path.moveTo(left, bottom);
        path.quadraticBezierTo(left + 2, top + 2, midX + 2, top + 1);
        path.lineTo(right, top + 1);
        break;
      case 2: // BP12 (BP)
        path.moveTo(left, bottom);
        path.quadraticBezierTo(midX - 4, top, midX, top + 1);
        path.quadraticBezierTo(midX + 4, top, right, bottom);
        break;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PmFilterCurvePainter oldDelegate) {
    return oldDelegate.index != index ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
