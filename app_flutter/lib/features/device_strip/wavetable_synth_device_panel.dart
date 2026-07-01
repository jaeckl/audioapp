import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'filter_preview.dart';
import 'panels/device_panel_theme.dart';
import 'panels/device_section_card.dart';
import 'panels/filter_mode_selector.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'sampler_envelope_preview.dart';
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
    final knobScale = _knobSize * 0.76;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 260.0;
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : WavetableSynthDevicePanel.designWidth;

          final gap = availableWidth < 360 ? 4.0 : 6.0;
          final previewHeight = (availableHeight * 0.48).clamp(86.0, 126.0).toDouble();
          final unisonWidth = (availableWidth * 0.28).clamp(92.0, 118.0).toDouble();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: previewHeight,
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
                    SizedBox(height: gap),
                    Expanded(
                      child: _panelBox(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                        child: _knobGridRow(
                          knobScale: knobScale,
                          slots: [
                            _knob(
                              label: 'Position',
                              value: widget.device.wtPosition,
                              size: knobScale,
                              displayValue: SamplerDevicePanel.formatPercent(widget.device.wtPosition),
                              onChanged: (v) => widget.onParameterChanged('wtPosition', v),
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
                              onChanged: (v) => widget.onParameterChanged('wtOctave', v),
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
                              onChanged: (v) => widget.onParameterChanged('wtSemitone', v),
                              paramId: 'wtSemitone',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                            _knob(
                              label: 'Fine',
                              value: widget.device.wtFine,
                              size: knobScale,
                              displayValue: _formatFine(widget.device.wtFine),
                              onChanged: (v) => widget.onParameterChanged('wtFine', v),
                              paramId: 'wtFine',
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
              ),
              SizedBox(width: gap),
              SizedBox(
                width: unisonWidth,
                child: _unisonColumn(knobScale: knobScale),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _unisonColumn({
    required double knobScale,
  }) {
    return _panelBox(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'UNISON',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _knob(
                  label: 'Voices',
                  value: widget.device.wtUnison,
                  size: knobScale,
                  labelGap: 1,
                  displayValue: '${1 + (widget.device.wtUnison * 7).round()}',
                  onChanged: (v) => widget.onParameterChanged('wtUnison', v),
                  paramId: 'wtUnison',
                  modulationAmounts: widget.modulationAmounts,
                  connectModeLfoId: widget.connectModeLfoId,
                  onModulationAssign: widget.onModulationAssign,
                ),
              ),
            ),
          ),
          Divider(
            height: 8,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _knob(
                  label: 'Detune',
                  value: widget.device.wtDetune,
                  size: knobScale,
                  labelGap: 1,
                  displayValue: SamplerDevicePanel.formatPercent(widget.device.wtDetune),
                  onChanged: (v) => widget.onParameterChanged('wtDetune', v),
                  paramId: 'wtDetune',
                  modulationAmounts: widget.modulationAmounts,
                  connectModeLfoId: widget.connectModeLfoId,
                  onModulationAssign: widget.onModulationAssign,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTab() {
    final mode = widget.device.filterMode.clamp(
      0,
      WavetableSynthDevicePanel._filterTypes.length - 1,
    );
    final knobScale = _knobSize * 0.76;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 240.0;
          final previewHeight = (availableHeight * 0.36).clamp(56.0, 82.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DevicePreviewFrame(
                height: previewHeight,
                child: FilterPreview(
                  cutoffHz: _filterCutoffHz(widget.device.filterCutoff),
                  q: _filterQ(widget.device.filterResonance),
                  mode: _filterPreviewMode(mode),
                  accent: WavetableSynthDevicePanel.accent,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: DeviceSectionCard(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'FILTER',
                        textAlign: TextAlign.center,
                        style: DevicePanelTheme.sectionLabel,
                      ),
                      const SizedBox(height: 4),
                      FilterModeSelector(
                        selectedIndex: mode,
                        accentColor: WavetableSynthDevicePanel.accent,
                        onSelected: (index) =>
                            widget.onParameterChanged('filterMode', index.toDouble()),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: _knobGridRow(
                          knobScale: knobScale,
                          slots: [
                            _knob(
                              label: 'Cutoff',
                              value: widget.device.filterCutoff,
                              size: knobScale,
                              displayValue: SamplerDevicePanel.formatCutoffHz(widget.device.filterCutoff),
                              onChanged: (v) => widget.onParameterChanged('filterCutoff', v),
                              paramId: 'filterCutoff',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                            _knob(
                              label: 'Res',
                              value: widget.device.filterResonance,
                              size: knobScale,
                              displayValue: SamplerDevicePanel.formatQ(widget.device.filterResonance),
                              onChanged: (v) => widget.onParameterChanged('filterResonance', v),
                              paramId: 'filterResonance',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                            _knob(
                              label: 'Env Amt',
                              value: widget.device.filterEnvAmount,
                              size: knobScale,
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _envTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 240.0;
          final gap = availableHeight < 230 ? 4.0 : 6.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _envelopePanel(title: 'AMP ENV', isFilter: false)),
              SizedBox(height: gap),
              Expanded(child: _envelopePanel(title: 'FILTER ENV', isFilter: true)),
            ],
          );
        },
      ),
    );
  }

  Widget _envelopePanel({
    required String title,
    required bool isFilter,
  }) {
    final attack = isFilter ? widget.device.filterAttack : widget.device.attack;
    final decay = isFilter ? widget.device.filterDecay : widget.device.decay;
    final sustain = isFilter ? widget.device.filterSustain : widget.device.sustain;
    final release = isFilter ? widget.device.filterRelease : widget.device.release;

    return _panelBox(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : WavetableSynthDevicePanel.designWidth;
          final compact = availableWidth < 350;
          final previewWidth = compact
              ? 76.0
              : (availableWidth * 0.30).clamp(96.0, 132.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: previewWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SamplerEnvelopePreview(
                          attack: attack,
                          decay: decay,
                          sustain: sustain,
                          release: release,
                          accent: WavetableSynthDevicePanel.accent,
                          label: isFilter ? 'FILTER' : 'AMP',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Center(
                        child: _adsrRow(
                          attack: attack,
                          decay: decay,
                          sustain: sustain,
                          release: release,
                          spacing: compact ? 3 : 5,
                          onChanged: isFilter
                              ? (id, v) => widget.onParameterChanged(id, v)
                              : widget.onParameterChanged,
                          prefix: isFilter ? 'filter' : '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
              alignment: Alignment.center,
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
        prefix.isEmpty ? n : '$prefix${n[0].toUpperCase()}${n.substring(1)}';
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


  FilterPreviewMode _filterPreviewMode(int mode) {
    switch (mode.clamp(0, 3)) {
      case 1:
        return FilterPreviewMode.highPass;
      case 2:
        return FilterPreviewMode.bandPass;
      case 3:
        return FilterPreviewMode.notch;
      case 0:
      default:
        return FilterPreviewMode.lowPass;
    }
  }

  double _filterCutoffHz(double normalized) {
    const minHz = 20.0;
    const maxHz = 20000.0;
    final t = normalized.clamp(0.0, 1.0).toDouble();
    return minHz * math.pow(maxHz / minHz, t).toDouble();
  }

  double _filterQ(double normalized) {
    return 0.1 + normalized.clamp(0.0, 1.0).toDouble() * 9.9;
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
