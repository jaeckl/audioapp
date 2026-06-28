import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'wavetable_waveform_preview.dart';

enum WavetablePanelDensity { strip, editor }

enum WavetableSynthDeviceTab { osc, filter, env }

/// 3-tab wavetable synth panel: OSC · FILTER · ENV
class WavetableSynthDevicePanel extends StatefulWidget {
  const WavetableSynthDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.density = WavetablePanelDensity.strip,
    this.embeddedInCard = false,
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
    this.onOpenWavetableLibrary,
  });

  final WavetableSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final WavetablePanelDensity density;
  final bool embeddedInCard;
  final WavetableSynthDeviceTab? selectedTab;
  final ValueChanged<WavetableSynthDeviceTab>? onTabChanged;
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
  final VoidCallback? onOpenWavetableLibrary;

  static const Color accent = DeviceStripTheme.wavetableSynthAccent;

  static const double designWidth = 420;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'OSC', icon: Icons.waves),
    DeviceTabSpec(label: 'FILTER', icon: Icons.tune),
    DeviceTabSpec(label: 'ENV', icon: Icons.show_chart),
  ];

  static const _filterTypes = ['LP', 'HP', 'BP', 'Notch'];

  @override
  State<WavetableSynthDevicePanel> createState() => _WavetableSynthDevicePanelState();
}

class _WavetableSynthDevicePanelState extends State<WavetableSynthDevicePanel> {
  late WavetableSynthDeviceTab _tab;

  WavetableSynthDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _knobSize => widget.density == WavetablePanelDensity.editor
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
      accentColor: WavetableSynthDevicePanel.accent,
      modulationActive: paramId != null && widget.modulatedParams.contains(paramId),
      automationActive: paramId != null && widget.automatedParams.contains(paramId),
      modulationAmount: modAmount,
      connectModeActive: paramId != null && connectModeLfoId != null,
      onModulationAssign: paramId != null && onModulationAssign != null
          ? (a) => onModulationAssign(paramId, a)
          : null,
      linkModeActive: paramId != null && widget.automationLinkActive,
      linkModeAccent: LibraryTheme.accentAutomation,
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
    bool showBorder = true,
    EdgeInsetsGeometry padding = const EdgeInsets.all(4),
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
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
    _tab = WavetableSynthDeviceTab.osc;
  }

  @override
  void didUpdateWidget(covariant WavetableSynthDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null && widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_activeTab) {
      WavetableSynthDeviceTab.osc => _oscTab(),
      WavetableSynthDeviceTab.filter => _filterTab(),
      WavetableSynthDeviceTab.env => _envTab(),
    };

    if (widget.embeddedInCard) {
      return body;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeviceTabBar(
          tabs: WavetableSynthDevicePanel.containerTabs,
          selectedIndex: _activeTab.index,
          accentColor: WavetableSynthDevicePanel.accent,
          onSelected: (i) {
            final tab = WavetableSynthDeviceTab.values[i];
            setState(() => _tab = tab);
            widget.onTabChanged?.call(tab);
          },
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _oscTab() {
    final knobScale = _knobSize * 0.78;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tappable wavetable preview
          SizedBox(
            height: 150,
            child: _panelBox(
              padding: EdgeInsets.zero,
                child: WavetableWaveformPreview(
                accent: WavetableSynthDevicePanel.accent,
                showLabel: true,
                label: widget.device.wavetableId,
                onTap: widget.onOpenWavetableLibrary,
                wavetableId: widget.device.wavetableId,
                wtPosition: widget.device.wtPosition,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Position knob + unison column
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 8,
                  child: _knobGridRow(
                    knobScale: knobScale,
                    slots: [
                      _knob(
                        label: 'Position',
                        value: widget.device.wtPosition,
                        size: knobScale,
                        displayValue:
                            SamplerDevicePanel.formatPercent(widget.device.wtPosition),
                        onChanged: (v) =>
                            widget.onParameterChanged('wtPosition', v),
                        paramId: 'wtPosition',
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'Octave',
                        value: widget.device.wtOctave,
                        size: knobScale,
                        displayValue: _formatOctave(widget.device.wtOctave),
                        onChanged: (v) =>
                            widget.onParameterChanged('wtOctave', v),
                        paramId: 'wtOctave',
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'Semi',
                        value: widget.device.wtSemitone,
                        size: knobScale,
                        displayValue: _formatSemitone(widget.device.wtSemitone),
                        onChanged: (v) =>
                            widget.onParameterChanged('wtSemitone', v),
                        paramId: 'wtSemitone',
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Unison column
                Expanded(
                  flex: 4,
                  child: _panelBox(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Column(
                      children: [
                        const Text(
                          'UNISON',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: _knob(
                            label: 'Voices',
                            value: widget.device.wtUnison,
                            size: knobScale * 0.78,
                            labelGap: 0,
                            displayValue:
                                '${1 + (widget.device.wtUnison * 7).round()}',
                            onChanged: (v) =>
                                widget.onParameterChanged('wtUnison', v),
                            paramId: 'wtUnison',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ),
                        Expanded(
                          child: _knob(
                            label: 'Detune',
                            value: widget.device.wtDetune,
                            size: knobScale * 0.78,
                            labelGap: 0,
                            displayValue:
                                SamplerDevicePanel.formatPercent(widget.device.wtDetune),
                            onChanged: (v) =>
                                widget.onParameterChanged('wtDetune', v),
                            paramId: 'wtDetune',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Fine knob row
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: _knob(
                    label: 'Fine',
                    value: widget.device.wtFine,
                    size: knobScale,
                    labelGap: 0,
                    displayValue: _formatFine(widget.device.wtFine),
                    onChanged: (v) => widget.onParameterChanged('wtFine', v),
                    paramId: 'wtFine',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab() {
    final mode = widget.device.filterMode.clamp(
        0, WavetableSynthDevicePanel._filterTypes.length - 1);
    final knobScale = _knobSize * 0.78;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter mode buttons
          SizedBox(
            height: 26,
            child: _panelBox(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                children: List.generate(
                  WavetableSynthDevicePanel._filterTypes.length,
                  (i) {
                    final active = mode == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onParameterChanged('filterMode', i.toDouble()),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: active
                                ? WavetableSynthDevicePanel.accent.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              WavetableSynthDevicePanel._filterTypes[i],
                              style: TextStyle(
                                color: active
                                    ? WavetableSynthDevicePanel.accent
                                    : Colors.white38,
                                fontSize: 9,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Cutoff + Res + Env Amt
          Expanded(
            child: _knobGridRow(
              knobScale: knobScale,
              slots: [
                _knob(
                  label: 'Cutoff',
                  value: widget.device.filterCutoff,
                  size: knobScale,
                  displayValue:
                      SamplerDevicePanel.formatCutoffHz(widget.device.filterCutoff),
                  onChanged: (v) =>
                      widget.onParameterChanged('filterCutoff', v),
                  paramId: 'filterCutoff',
                  modulationAmounts: widget.modulationAmounts,
                  connectModeLfoId: widget.connectModeLfoId,
                  onModulationAssign: widget.onModulationAssign,
                ),
                _knob(
                  label: 'Res',
                  value: widget.device.filterResonance,
                  size: knobScale,
                  displayValue:
                      SamplerDevicePanel.formatQ(widget.device.filterResonance),
                  onChanged: (v) =>
                      widget.onParameterChanged('filterResonance', v),
                  paramId: 'filterResonance',
                  modulationAmounts: widget.modulationAmounts,
                  connectModeLfoId: widget.connectModeLfoId,
                  onModulationAssign: widget.onModulationAssign,
                ),
                _knob(
                  label: 'Env Amt',
                  value: widget.device.filterEnvAmount,
                  size: knobScale,
                  displayValue:
                      SamplerDevicePanel.formatPercent(widget.device.filterEnvAmount),
                  onChanged: (v) =>
                      widget.onParameterChanged('filterEnvAmount', v),
                  paramId: 'filterEnvAmount',
                  modulationAmounts: widget.modulationAmounts,
                  connectModeLfoId: widget.connectModeLfoId,
                  onModulationAssign: widget.onModulationAssign,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Filter envelope
          _panelBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FILTER ENV',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }

  Widget _envTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amp envelope
          Expanded(
            child: _panelBox(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'AMP ENV',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Center(
                      child: _adsrRow(
                        attack: widget.device.attack,
                        decay: widget.device.decay,
                        sustain: widget.device.sustain,
                        release: widget.device.release,
                        onChanged: widget.onParameterChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Filter envelope
          Expanded(
            child: _panelBox(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'FILTER ENV',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Center(
                      child: _adsrRow(
                        attack: widget.device.filterAttack,
                        decay: widget.device.filterDecay,
                        sustain: widget.device.filterSustain,
                        release: widget.device.filterRelease,
                        onChanged: (id, v) => widget.onParameterChanged(id, v),
                        prefix: 'filter',
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

  Widget _knobGridRow({
    required double knobScale,
    required List<Widget?> slots,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slot in slots)
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: slot == null
                  ? const SizedBox.shrink()
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: slot,
                    ),
            ),
          ),
      ],
    );
  }

  Widget _adsrRow({
    required double attack,
    required double decay,
    required double sustain,
    required double release,
    required void Function(String id, double value) onChanged,
    String prefix = '',
    double spacing = 6,
  }) {
    final size = _knobSize * 0.78;
    String id(String n) =>
        prefix.isEmpty ? n : '${prefix}${n[0].toUpperCase()}${n.substring(1)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _knob(label: 'A', value: attack, size: size, labelGap: 1,
          displayValue: SamplerDevicePanel.formatPercent(attack),
          onChanged: (v) => onChanged(id('attack'), v),
          paramId: id('attack'),
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(label: 'D', value: decay, size: size, labelGap: 1,
          displayValue: SamplerDevicePanel.formatPercent(decay),
          onChanged: (v) => onChanged(id('decay'), v),
          paramId: id('decay'),
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(label: 'S', value: sustain, size: size, labelGap: 1,
          displayValue: SamplerDevicePanel.formatPercent(sustain),
          onChanged: (v) => onChanged(id('sustain'), v),
          paramId: id('sustain'),
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(label: 'R', value: release, size: size, labelGap: 1,
          displayValue: SamplerDevicePanel.formatPercent(release),
          onChanged: (v) => onChanged(id('release'), v),
          paramId: id('release'),
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId),
      ],
    );
  }

  String _formatOctave(double normalized) {
    final oct = ((normalized - 0.5) * 4).round();
    if (oct == 0) return '0';
    return oct > 0 ? '+$oct' : '$oct';
  }

  String _formatSemitone(double normalized) {
    final semi = ((normalized - 0.5) * 48).round();
    if (semi == 0) return '0';
    return semi > 0 ? '+$semi' : '$semi';
  }

  String _formatFine(double normalized) {
    final cents = ((normalized - 0.5) * 100).round();
    if (cents == 0) return '0\u00A2';
    return cents > 0 ? '+$cents\u00A2' : '$cents\u00A2';
  }
}
