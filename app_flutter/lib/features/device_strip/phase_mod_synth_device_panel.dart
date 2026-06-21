import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';

enum PhaseModSynthPanelDensity { strip, editor }

enum PhaseModSynthDeviceTab { algo, op, mod, tone }

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

  final DeviceSnapshot device;
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
    DeviceTabSpec(label: 'ALGO', icon: Icons.account_tree),
    DeviceTabSpec(label: 'OP', icon: Icons.tune),
    DeviceTabSpec(label: 'MOD', icon: Icons.waves),
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

  static String lfoShapeDisplay(double value) {
    final idx = (value * 4).round().clamp(0, 4);
    return const ['Sine', 'Tri', 'Saw', 'Sq', 'S&H'][idx];
  }

  static String lfoDestDisplay(double value) {
    final idx = value.round().clamp(0, 4);
    return const ['Off', 'Pitch', 'Filter', 'Amp', 'PM Amt'][idx];
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

  double get _knobSize => widget.density == PhaseModSynthPanelDensity.editor
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

  Widget _toggleKnob({
    required String label,
    required double value,
    required String paramId,
    required String onLabel,
    required String offLabel,
  }) {
    final isOn = value >= 0.5;
    return GestureDetector(
      onTap: () => widget.onParameterChanged(paramId, isOn ? 0.0 : 1.0),
      child: Container(
        width: _knobSize * 0.85,
        height: _knobSize * 0.85,
        decoration: BoxDecoration(
          color: isOn
              ? PhaseModSynthDevicePanel.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOn
                ? PhaseModSynthDevicePanel.accent
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isOn ? onLabel : offLabel,
              style: TextStyle(
                color: isOn ? PhaseModSynthDevicePanel.accent : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required List<String> itemLabels,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              dropdownColor: const Color(0xFF2A2A34),
              style: const TextStyle(color: Colors.white, fontSize: 11),
              items: List.generate(items.length, (i) {
                return DropdownMenuItem<T>(
                  value: items[i],
                  child: Text(itemLabels[i], style: const TextStyle(fontSize: 11)),
                );
              }),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
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
  }

  Widget _adsrRow({
    required String prefix,
    required double a,
    required double d,
    required double s,
    required double r,
    bool useSmallKnobs = true,
  }) {
    final kSize = useSmallKnobs ? _knobSize * 0.72 : _knobSize;
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
    _tab = PhaseModSynthDeviceTab.algo;
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
    return body;
  }

  Widget _buildTabContent() {
    return switch (_activeTab) {
      PhaseModSynthDeviceTab.algo => _algoTab(),
      PhaseModSynthDeviceTab.op => _opTab(),
      PhaseModSynthDeviceTab.mod => _modTab(),
      PhaseModSynthDeviceTab.tone => _toneTab(),
    };
  }

  // ── ALGO tab ──────────────────────────────────────────────────────────

  Widget _algoTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                children: [
                  const Text(
                    'Algorithm',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _algoSelector(),
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
                    label: 'Feedback',
                    value: widget.device.pmFeedback,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.pmFeedback),
                    onChanged: (v) => widget.onParameterChanged('pmFeedback', v),
                    paramId: 'pmFeedback',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Master Vol',
                    value: widget.device.pmMasterVol,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.pmMasterVol),
                    onChanged: (v) => widget.onParameterChanged('pmMasterVol', v),
                    paramId: 'pmMasterVol',
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

  Widget _algoSelector() {
    final accent = PhaseModSynthDevicePanel.accent;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (i) {
        final selected = widget.device.pmAlgoIndex == i;
        return GestureDetector(
          onTap: () => widget.onParameterChanged('pmAlgoIndex', i.toDouble()),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 32,
            height: 28,
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: selected ? accent : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── OP tab ────────────────────────────────────────────────────────────

  Widget _opTab() {
    final kSize = _knobSize;
    final smallKnob = kSize * 0.72;
    final accent = PhaseModSynthDevicePanel.accent;
    final op = _selectedOperator;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Operator selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final selected = op == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedOperator = i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 38,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.06),
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
          const SizedBox(height: 4),
          // Ratio + Fine row
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _dropdown<double>(
                    label: 'Ratio',
                    value: _opParam(op, 'ratio'),
                    items: List.generate(9, (i) => i / 8.0),
                    itemLabels: PhaseModSynthDevicePanel._ratioValues
                        .map((r) => r.toString())
                        .toList(),
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'Ratio'),
                      v,
                    ),
                  ),
                  _knob(
                    label: 'Fine',
                    value: _opParam(op, 'fine'),
                    size: smallKnob,
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
                    label: 'Level',
                    value: _opParam(op, 'level'),
                    size: smallKnob,
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
                  _dropdown<double>(
                    label: 'Wave',
                    value: _opParam(op, 'wave'),
                    items: [0.0, 0.25, 0.5, 0.75, 1.0],
                    itemLabels: const ['Sine', 'Tri', 'Saw', 'Sq', 'Noise'],
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'Wave'),
                      v,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ADSR row
          Expanded(
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _opAdsrRow(op),
            ),
          ),
          const SizedBox(height: 4),
          // Vel Sense + Key Track row
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'Vel Sense',
                    value: _opParam(op, 'velSense'),
                    size: smallKnob,
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
                    size: smallKnob,
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
        ],
      ),
    );
  }

  Widget _opAdsrRow(int op) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _knob(
          label: 'A',
          value: _opParam(op, 'attack'),
          size: _knobSize * 0.72,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'attack')),
          onChanged: (v) => widget.onParameterChanged(_opParamId(op, 'Attack'), v),
          paramId: _opParamId(op, 'Attack'),
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'D',
          value: _opParam(op, 'decay'),
          size: _knobSize * 0.72,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'decay')),
          onChanged: (v) => widget.onParameterChanged(_opParamId(op, 'Decay'), v),
          paramId: _opParamId(op, 'Decay'),
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'S',
          value: _opParam(op, 'sustain'),
          size: _knobSize * 0.72,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'sustain')),
          onChanged: (v) => widget.onParameterChanged(_opParamId(op, 'Sustain'), v),
          paramId: _opParamId(op, 'Sustain'),
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'R',
          value: _opParam(op, 'release'),
          size: _knobSize * 0.72,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(_opParam(op, 'release')),
          onChanged: (v) => widget.onParameterChanged(_opParamId(op, 'Release'), v),
          paramId: _opParamId(op, 'Release'),
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
      ],
    );
  }

  // ── MOD tab ───────────────────────────────────────────────────────────

  Widget _modTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LFO section
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(
                      'LFO',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _knob(
                          label: 'Rate',
                          value: widget.device.pmLfoRate,
                          size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.pmLfoRate),
                          onChanged: (v) => widget.onParameterChanged('pmLfoRate', v),
                          paramId: 'pmLfoRate',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                        _dropdown<double>(
                          label: 'Shape',
                          value: widget.device.pmLfoShape,
                          items: [0.0, 0.25, 0.5, 0.75, 1.0],
                          itemLabels: const ['Sine', 'Tri', 'Saw', 'Sq', 'S&H'],
                          onChanged: (v) => widget.onParameterChanged('pmLfoShape', v),
                        ),
                        _knob(
                          label: 'Amount',
                          value: widget.device.pmLfoAmount,
                          size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.pmLfoAmount),
                          onChanged: (v) => widget.onParameterChanged('pmLfoAmount', v),
                          paramId: 'pmLfoAmount',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // LFO Destination row
          Expanded(
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _dropdown<int>(
                    label: 'LFO Dest',
                    value: widget.device.pmLfoDest.clamp(0, 4),
                    items: [0, 1, 2, 3, 4],
                    itemLabels: const ['Off', 'Pitch', 'Filter', 'Amp', 'PM Amt'],
                    onChanged: (v) => widget.onParameterChanged('pmLfoDest', v.toDouble()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Vibrato section
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(
                      'Vibrato',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _knob(
                          label: 'Rate',
                          value: widget.device.pmVibratoRate,
                          size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.pmVibratoRate),
                          onChanged: (v) => widget.onParameterChanged('pmVibratoRate', v),
                          paramId: 'pmVibratoRate',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                        _knob(
                          label: 'Depth',
                          value: widget.device.pmVibratoDepth,
                          size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(widget.device.pmVibratoDepth),
                          onChanged: (v) => widget.onParameterChanged('pmVibratoDepth', v),
                          paramId: 'pmVibratoDepth',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                      ],
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

  // ── TONE tab ──────────────────────────────────────────────────────────

  Widget _toneTab() {
    final kSize = _knobSize;
    final smallKnob = kSize * 0.72;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter section
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    value: widget.device.filterQ,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatQ(widget.device.filterQ),
                    onChanged: (v) => widget.onParameterChanged('filterQ', v),
                    paramId: 'filterQ',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _dropdown<int>(
                    label: 'Type',
                    value: widget.device.filterMode.clamp(0, 5),
                    items: [0, 1, 2, 3, 4, 5],
                    itemLabels: const ['LP24', 'LP12', 'BP12', 'HP12', 'HP24', 'LP6'],
                    onChanged: (v) => widget.onParameterChanged('filterMode', v.toDouble()),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Filter ADSR
          Expanded(
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _adsrRow(
                prefix: 'filter',
                a: widget.device.filterAttack,
                d: widget.device.filterDecay,
                s: widget.device.filterSustain,
                r: widget.device.filterRelease,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Amp ADSR
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: _adsrRow(
                prefix: '',
                a: widget.device.attack,
                d: widget.device.decay,
                s: widget.device.sustain,
                r: widget.device.release,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Master Vol, Pan, Unison Voices, Unison Detune
          Expanded(
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'Volume',
                    value: widget.device.gain,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.gain),
                    onChanged: (v) => widget.onParameterChanged('gain', v),
                    paramId: 'gain',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Pan',
                    value: widget.device.pan,
                    size: kSize,
                    displayValue: '${((widget.device.pan - 0.5) * 200).round()}',
                    onChanged: (v) => widget.onParameterChanged('pan', v),
                    paramId: 'pan',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Unison',
                    value: widget.device.pmUnisonVoices,
                    size: smallKnob,
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
                    size: smallKnob,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.pmUnisonDetune),
                    onChanged: (v) => widget.onParameterChanged('pmUnisonDetune', v),
                    paramId: 'pmUnisonDetune',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Glide, Mono, Legato
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'Glide',
                    value: widget.device.pmGlide,
                    size: smallKnob,
                    displayValue: widget.device.pmGlide <= 0.001
                        ? 'Off'
                        : '${(widget.device.pmGlide * 2000).round()} ms',
                    onChanged: (v) => widget.onParameterChanged('pmGlide', v),
                    paramId: 'pmGlide',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _toggleKnob(
                    label: '',
                    value: widget.device.pmMono,
                    paramId: 'pmMono',
                    onLabel: 'MONO',
                    offLabel: 'POLY',
                  ),
                  _toggleKnob(
                    label: '',
                    value: widget.device.pmLegato,
                    paramId: 'pmLegato',
                    onLabel: 'LEG',
                    offLabel: 'NORM',
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