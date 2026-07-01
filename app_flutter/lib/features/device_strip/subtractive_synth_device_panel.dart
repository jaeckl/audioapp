import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'draggable_int_value_box.dart';
import 'panels/device_panel_theme.dart';
import 'panels/device_section_card.dart';
import 'panels/filter_mode_selector.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'sampler_envelope_preview.dart';
import 'subtractive_filter_preview.dart';
import 'subtractive_waveform_preview.dart';

enum SubtractivePanelDensity { strip, editor }

/// Signal-flow tabs: sound source, spectral shaping, and articulation.
enum SubtractiveDeviceTab { osc, filter, amp }

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
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final SubtractiveSynthDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final SubtractivePanelDensity density;
  final bool embeddedInCard;
  final SubtractiveDeviceTab? selectedTab;
  final ValueChanged<SubtractiveDeviceTab>? onTabChanged;
  final VoidCallback? onOpenFullscreen;
  final bool showExpandControl;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = DeviceStripTheme.subtractiveSynthAccent;

  /// 3-tab subtractive synth layout (Osc · Filter · Amp).
  static const double designWidth = 500;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Osc', icon: Icons.waves),
    DeviceTabSpec(label: 'Filter', icon: Icons.filter_alt_outlined),
    DeviceTabSpec(label: 'Amp', icon: Icons.graphic_eq),
  ];

  static const _mixModes = ['Mix', 'Neg', 'AM', 'Sign', 'Max'];
  static const _filterTypes = [
    'LP 12',
    'HP 12',
    'Band',
    'Notch',
    'FB',
    'LP 24'
  ];
  static const _shaperModes = ['Off', 'Soft', 'Hard', 'Fold'];

  static String formatGlobalPitch(double normalized) {
    final st = ((normalized - 0.5) * 24).round();
    if (st == 0) return '0';
    return st > 0 ? '+$st' : '$st';
  }

  @override
  State<SubtractiveSynthDevicePanel> createState() =>
      _SubtractiveSynthDevicePanelState();
}

class _SubtractiveSynthDevicePanelState
    extends State<SubtractiveSynthDevicePanel> {
  late SubtractiveDeviceTab _tab;
  int _selectedOscillator = 0;

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
      accentColor: SubtractiveSynthDevicePanel.accent,
      modulationActive:
          paramId != null && widget.modulatedParams.contains(paramId),
      automationActive:
          paramId != null && widget.automatedParams.contains(paramId),
      modulationAmount: modAmount,
      polarityParamId: paramId,
      deviceId: widget.device.id,
      lfos: widget.lfos,
      modEdges: widget.modEdges,
      connectModeLfoId: connectModeLfoId,
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
    if (widget.selectedTab != null &&
        widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_activeTab) {
      SubtractiveDeviceTab.osc => _oscTabV2(),
      SubtractiveDeviceTab.filter => _toneTab(),
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

  // ignore: unused_element
  Widget _legacyOscTab() {
    final knobScale = _knobSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 24,
                  child: Row(
                    children: [
                      Expanded(
                        child: _oscSelectorButton(
                          label: 'OSC 1',
                          selected: _selectedOscillator == 0,
                          onTap: () => setState(() => _selectedOscillator = 0),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _oscSelectorButton(
                          label: 'OSC 2',
                          selected: _selectedOscillator == 1,
                          onTap: () => setState(() => _selectedOscillator = 1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _selectedOscillator == 0
                      ? _oscBank(
                          shape: widget.device.osc1Shape,
                          shapeParam: 'osc1Shape',
                          semi: widget.device.osc1Semi,
                          semiParam: 'osc1Semi',
                          octaveNorm: widget.device.osc1Octave,
                          octaveParam: 'osc1Octave',
                          syncValue: widget.device.osc1Sync,
                          syncParam: 'osc1Sync',
                          syncDisplay: SamplerDevicePanel.formatPercent(
                              widget.device.osc1Sync),
                          detuneValue: widget.device.osc1Detune,
                          detuneParam: 'osc1Detune',
                          detuneDisplay:
                              '${((widget.device.osc1Detune - 0.5) * 100).round()}¢',
                          knobScale: knobScale,
                        )
                      : _oscBank(
                          shape: widget.device.osc2Shape,
                          shapeParam: 'osc2Shape',
                          semi: widget.device.osc2Semi,
                          semiParam: 'osc2Semi',
                          octaveNorm: widget.device.osc2Octave,
                          octaveParam: 'osc2Octave',
                          syncValue: widget.device.osc2Sync,
                          syncParam: 'osc2Sync',
                          syncDisplay: SamplerDevicePanel.formatPercent(
                              widget.device.osc2Sync),
                          detuneValue: widget.device.osc2Detune,
                          detuneParam: 'osc2Detune',
                          detuneDisplay:
                              '${((widget.device.osc2Detune - 0.5) * 100).round()}¢',
                          knobScale: knobScale,
                        ),
                ),
                const SizedBox(height: 4),
                _oscMixerRow(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: _panelBox(
              variant: PanelVariant.elevated,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              child: Column(
                children: [
                  const Text('VOICE', style: DevicePanelTheme.sectionLabel),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _knob(
                        label: 'Voices',
                        value: widget.device.unisonVoices,
                        size: 44,
                        displayValue:
                            '${1 + (widget.device.unisonVoices * 3).round()}',
                        onChanged: (v) =>
                            widget.onParameterChanged('unisonVoices', v),
                        paramId: 'unisonVoices',
                      ),
                      _knob(
                        label: 'Spread',
                        value: widget.device.unisonDetune,
                        size: 44,
                        displayValue: SamplerDevicePanel.formatPercent(
                            widget.device.unisonDetune),
                        onChanged: (v) =>
                            widget.onParameterChanged('unisonDetune', v),
                        paramId: 'unisonDetune',
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _knob(
                        label: 'Pitch',
                        value: widget.device.globalPitch,
                        size: 44,
                        displayValue:
                            SubtractiveSynthDevicePanel.formatGlobalPitch(
                                widget.device.globalPitch),
                        onChanged: (v) =>
                            widget.onParameterChanged('globalPitch', v),
                        paramId: 'globalPitch',
                      ),
                      _knob(
                        label: 'Feedback',
                        value: widget.device.mixFeedback,
                        size: 44,
                        displayValue: SamplerDevicePanel.formatPercent(
                            widget.device.mixFeedback),
                        onChanged: (v) =>
                            widget.onParameterChanged('mixFeedback', v),
                        paramId: 'mixFeedback',
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _oscTabV2() {
    final knobScale = _knobSize;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 24,
                        child: Row(
                          children: [
                            Expanded(
                              child: _oscSelectorButton(
                                label: 'OSC 1',
                                selected: _selectedOscillator == 0,
                                onTap: () =>
                                    setState(() => _selectedOscillator = 0),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _oscSelectorButton(
                                label: 'OSC 2',
                                selected: _selectedOscillator == 1,
                                onTap: () =>
                                    setState(() => _selectedOscillator = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _selectedOscillator == 0
                            ? _oscBank(
                                shape: widget.device.osc1Shape,
                                shapeParam: 'osc1Shape',
                                semi: widget.device.osc1Semi,
                                semiParam: 'osc1Semi',
                                octaveNorm: widget.device.osc1Octave,
                                octaveParam: 'osc1Octave',
                                syncValue: widget.device.osc1Sync,
                                syncParam: 'osc1Sync',
                                syncDisplay: SamplerDevicePanel.formatPercent(
                                    widget.device.osc1Sync),
                                detuneValue: widget.device.osc1Detune,
                                detuneParam: 'osc1Detune',
                                detuneDisplay:
                                    '${((widget.device.osc1Detune - 0.5) * 100).round()}¢',
                                knobScale: knobScale,
                              )
                            : _oscBank(
                                shape: widget.device.osc2Shape,
                                shapeParam: 'osc2Shape',
                                semi: widget.device.osc2Semi,
                                semiParam: 'osc2Semi',
                                octaveNorm: widget.device.osc2Octave,
                                octaveParam: 'osc2Octave',
                                syncValue: widget.device.osc2Sync,
                                syncParam: 'osc2Sync',
                                syncDisplay: SamplerDevicePanel.formatPercent(
                                    widget.device.osc2Sync),
                                detuneValue: widget.device.osc2Detune,
                                detuneParam: 'osc2Detune',
                                detuneDisplay:
                                    '${((widget.device.osc2Detune - 0.5) * 100).round()}¢',
                                knobScale: knobScale,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 132,
                  height: 100,
                  child: _panelBox(
                    variant: PanelVariant.elevated,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                    child: Column(
                      children: [
                        const Text('VOICE',
                            style: DevicePanelTheme.sectionLabel),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _knob(
                              label: 'Voices',
                              value: widget.device.unisonVoices,
                              size: 52,
                              labelGap: 0,
                              displayValue:
                                  '${1 + (widget.device.unisonVoices * 3).round()}',
                              onChanged: (v) =>
                                  widget.onParameterChanged('unisonVoices', v),
                              paramId: 'unisonVoices',
                            ),
                            _knob(
                              label: 'Spread',
                              value: widget.device.unisonDetune,
                              size: 52,
                              labelGap: 0,
                              displayValue: SamplerDevicePanel.formatPercent(
                                  widget.device.unisonDetune),
                              onChanged: (v) =>
                                  widget.onParameterChanged('unisonDetune', v),
                              paramId: 'unisonDetune',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _oscMixerRow(),
        ],
      ),
    );
  }

  Widget _oscMixerRow() {
    return SizedBox(
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'SOURCE MIX',
              style: DevicePanelTheme.sectionLabel,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              height: 22,
              child: _borderlessDropdown<int>(
                value: widget.device.oscMixMode
                    .clamp(0, SubtractiveSynthDevicePanel._mixModes.length - 1),
                items: List.generate(
                  SubtractiveSynthDevicePanel._mixModes.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(SubtractiveSynthDevicePanel._mixModes[i]),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) {
                    widget.onParameterChanged('oscMixMode', v.toDouble());
                  }
                },
              ),
            ),
            const Spacer(),
            _knob(
              label: 'Mix',
              value: widget.device.oscMix,
              size: 48,
              labelGap: 0,
              displayValue:
                  SamplerDevicePanel.formatPercent(widget.device.oscMix),
              onChanged: (v) => widget.onParameterChanged('oscMix', v),
              paramId: 'oscMix',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            const SizedBox(width: 12),
            _knob(
              label: 'Noise',
              value: widget.device.noiseLevel,
              size: 48,
              labelGap: 0,
              displayValue:
                  SamplerDevicePanel.formatPercent(widget.device.noiseLevel),
              onChanged: (v) => widget.onParameterChanged('noiseLevel', v),
              paramId: 'noiseLevel',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            const SizedBox(width: 12),
            _knob(
              label: 'Pitch',
              value: widget.device.globalPitch,
              size: 48,
              labelGap: 0,
              displayValue: SubtractiveSynthDevicePanel.formatGlobalPitch(
                  widget.device.globalPitch),
              onChanged: (v) => widget.onParameterChanged('globalPitch', v),
              paramId: 'globalPitch',
            ),
            const SizedBox(width: 12),
            _knob(
              label: 'Feedback',
              value: widget.device.mixFeedback,
              size: 48,
              labelGap: 0,
              displayValue:
                  SamplerDevicePanel.formatPercent(widget.device.mixFeedback),
              onChanged: (v) => widget.onParameterChanged('mixFeedback', v),
              paramId: 'mixFeedback',
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _oscOctaveSlot({
    required double knobScale,
    required int octave,
    required String octaveParam,
  }) {
    return DraggableIntValueBox(
      value: octave,
      controlSize: knobScale,
      label: 'Oct',
      accentColor: SubtractiveSynthDevicePanel.accent,
      onChanged: (v) => widget.onParameterChanged(
        octaveParam,
        subtractiveNormFromOctave(v),
      ),
    );
  }

  Widget _oscBank({
    required double shape,
    required String shapeParam,
    required double semi,
    required String semiParam,
    required double octaveNorm,
    required String octaveParam,
    required double syncValue,
    required String syncParam,
    required String syncDisplay,
    required double knobScale,
    double? detuneValue,
    String? detuneParam,
    String? detuneDisplay,
  }) {
    final octave = subtractiveOctaveFromNorm(octaveNorm);
    final hasDetune =
        detuneValue != null && detuneParam != null && detuneDisplay != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 68,
          child: _panelBox(
            variant: PanelVariant.screen,
            padding: EdgeInsets.zero,
            child: SubtractiveWaveformPreview(
              shape: shape,
              accent: SubtractiveSynthDevicePanel.accent,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _oscKnobGridRow(
            knobScale: knobScale,
            slots: [
              _knob(
                label: 'Shape',
                value: shape,
                size: knobScale,
                displayValue: subtractiveShapeLabel(shape),
                onChanged: (v) => widget.onParameterChanged(shapeParam, v),
                paramId: shapeParam,
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
              _oscOctaveSlot(
                knobScale: knobScale,
                octave: octave,
                octaveParam: octaveParam,
              ),
              _knob(
                label: 'Semi',
                value: semi,
                size: knobScale,
                displayValue: '${(semi * 11).round()}',
                onChanged: (v) => widget.onParameterChanged(semiParam, v),
                paramId: semiParam,
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
              hasDetune
                  ? _knob(
                      label: 'Fine',
                      value: detuneValue,
                      size: knobScale,
                      displayValue: detuneDisplay,
                      onChanged: (v) =>
                          widget.onParameterChanged(detuneParam, v),
                      paramId: detuneParam,
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    )
                  : null,
              _knob(
                label: 'Sync',
                value: syncValue,
                size: knobScale,
                displayValue: syncDisplay,
                onChanged: (v) => widget.onParameterChanged(syncParam, v),
                paramId: syncParam,
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Kept temporarily as a parameter-layout reference while Filter/Amp migration settles.
  // ignore: unused_element
  Widget _legacyMixTab() {
    final knobScale = _knobSize * 0.78;
    final envKnob = _knobSize * 0.76;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _mixColumn(
                  title: 'PRE-FILTER',
                  row1: _knob(
                    label: 'HP Cut',
                    value: widget.device.preHpCutoff,
                    size: knobScale,
                    displayValue: widget.device.preHpCutoff <= 0.02
                        ? 'Off'
                        : SamplerDevicePanel.formatCutoffHz(
                            widget.device.preHpCutoff),
                    onChanged: (v) =>
                        widget.onParameterChanged('preHpCutoff', v),
                    paramId: 'preHpCutoff',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row2: _knob(
                    label: 'HP Res',
                    value: widget.device.preHpRes,
                    size: knobScale,
                    displayValue:
                        SamplerDevicePanel.formatQ(widget.device.preHpRes),
                    onChanged: (v) => widget.onParameterChanged('preHpRes', v),
                    paramId: 'preHpRes',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row3: _knob(
                    label: 'Drive',
                    value: widget.device.preDrive,
                    size: knobScale,
                    displayValue: SamplerDevicePanel.formatPercent(
                        widget.device.preDrive),
                    onChanged: (v) => widget.onParameterChanged('preDrive', v),
                    paramId: 'preDrive',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ),
                const SizedBox(width: 6),
                _mixColumn(
                  title: 'GLOBAL',
                  row1: _knob(
                    label: 'Pitch',
                    value: widget.device.globalPitch,
                    size: knobScale,
                    displayValue: SubtractiveSynthDevicePanel.formatGlobalPitch(
                        widget.device.globalPitch),
                    onChanged: (v) =>
                        widget.onParameterChanged('globalPitch', v),
                    paramId: 'globalPitch',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row2: _knob(
                    label: 'FB',
                    value: widget.device.mixFeedback,
                    size: knobScale,
                    displayValue: SamplerDevicePanel.formatPercent(
                        widget.device.mixFeedback),
                    onChanged: (v) =>
                        widget.onParameterChanged('mixFeedback', v),
                    paramId: 'mixFeedback',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row3: _knob(
                    label: 'Vel',
                    value: widget.device.velocitySensitivity,
                    size: knobScale,
                    displayValue: SamplerDevicePanel.formatPercent(
                        widget.device.velocitySensitivity),
                    onChanged: (v) =>
                        widget.onParameterChanged('velocitySensitivity', v),
                    paramId: 'velocitySensitivity',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _envelopePanel(
                  title: 'FEG',
                  maxKnob: envKnob,
                  attack: widget.device.filterAttack,
                  decay: widget.device.filterDecay,
                  sustain: widget.device.filterSustain,
                  release: widget.device.filterRelease,
                  onChanged: (id, v) => widget.onParameterChanged(id, v),
                  prefix: 'filter',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _envelopePanel(
                  title: 'AEG',
                  maxKnob: envKnob,
                  attack: widget.device.attack,
                  decay: widget.device.decay,
                  sustain: widget.device.sustain,
                  release: widget.device.release,
                  onChanged: widget.onParameterChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ampTab() {
    final monoOn = widget.device.synthMono >= 0.5;
    final legatoOn = widget.device.synthLegato >= 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 19,
            child: _panelBox(
              variant: PanelVariant.screen,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DevicePreviewFrame(
                    height: 126,
                    child: SamplerEnvelopePreview(
                      attack: widget.device.attack,
                      decay: widget.device.decay,
                      sustain: widget.device.sustain,
                      release: widget.device.release,
                      accent: SubtractiveSynthDevicePanel.accent,
                      label: '',
                    ),
                  ),
                  const SizedBox(height: 6),
                  _adsrRow(
                    attack: widget.device.attack,
                    decay: widget.device.decay,
                    sustain: widget.device.sustain,
                    release: widget.device.release,
                    onChanged: widget.onParameterChanged,
                    knobScale: _knobSize,
                    spacing: 8,
                    labelGap: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 11,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 144,
                child: _panelBox(
                  variant: PanelVariant.elevated,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  child: Column(
                    children: [
                      const Text('PERFORMANCE',
                          style: DevicePanelTheme.sectionLabel),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _flatToggle(
                              label: monoOn ? 'Mono' : 'Poly',
                              active: monoOn,
                              onTap: () => widget.onParameterChanged(
                                  'synthMono', monoOn ? 0.0 : 1.0),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _flatToggle(
                              label: 'Legato',
                              active: legatoOn,
                              onTap: () => widget.onParameterChanged(
                                  'synthLegato', legatoOn ? 0.0 : 1.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _knob(
                            label: 'Glide',
                            value: widget.device.glideMs,
                            displayValue: widget.device.glideMs <= 0.001
                                ? 'Off'
                                : '${(widget.device.glideMs * 2000).round()} ms',
                            onChanged: (v) =>
                                widget.onParameterChanged('glideMs', v),
                            paramId: 'glideMs',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(
                            label: 'Velocity',
                            value: widget.device.velocitySensitivity,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.velocitySensitivity),
                            onChanged: (v) => widget.onParameterChanged(
                                'velocitySensitivity', v),
                            paramId: 'velocitySensitivity',
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _envelopePanel({
    required String title,
    required double maxKnob,
    required double attack,
    required double decay,
    required double sustain,
    required double release,
    required void Function(String id, double value) onChanged,
    String prefix = '',
  }) {
    return _panelBox(
      variant: PanelVariant.screen,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          _adsrRow(
            attack: attack,
            decay: decay,
            sustain: sustain,
            release: release,
            onChanged: onChanged,
            prefix: prefix,
            knobScale: maxKnob,
            spacing: 6,
            labelGap: 0,
          ),
        ],
      ),
    );
  }

  Widget _mixColumn({
    required String title,
    required Widget row1,
    required Widget row2,
    required Widget row3,
  }) {
    return Expanded(
      child: _panelBox(
        variant: PanelVariant.elevated,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
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
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [row1, row2, row3],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toneTab() {
    final mode = widget.device.filterMode
        .clamp(0, SubtractiveSynthDevicePanel._filterTypes.length - 1);
    final shaperMode = widget.device.filterShaperMode
        .clamp(0, SubtractiveSynthDevicePanel._shaperModes.length - 1);
    final filterKnob = _knobSize;
    final colorKnob = _knobSize * 0.86;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: DevicePanelTheme.previewHeroHeight,
            child: DevicePreviewFrame(
              height: DevicePanelTheme.previewHeroHeight,
              child: SubtractiveFilterPreview(
                filterMode: mode,
                filterCutoff: widget.device.filterCutoff,
                filterQ: widget.device.filterQ,
                accent: SubtractiveSynthDevicePanel.accent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: _panelBox(
                    variant: PanelVariant.elevated,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilterModeSelector(
                          selectedIndex: mode,
                          accentColor: SubtractiveSynthDevicePanel.accent,
                          overflowOptions: const [
                            FilterModeOverflowOption(index: 4, label: 'FB'),
                            FilterModeOverflowOption(index: 5, label: 'LP 24'),
                          ],
                          onSelected: (index) => widget.onParameterChanged(
                              'filterMode', index.toDouble()),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _filterKeyTrackToggle(),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 22),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 10,
                                      color: widget.device.filterKeyTrack >
                                              0.001
                                          ? SubtractiveSynthDevicePanel.accent
                                          : Colors.white24,
                                    ),
                                  ),
                                  _knob(
                                    label: 'Cutoff',
                                    value: widget.device.filterCutoff,
                                    size: filterKnob,
                                    labelGap: 1,
                                    displayValue:
                                        SamplerDevicePanel.formatCutoffHz(
                                      widget.device.filterCutoff,
                                    ),
                                    onChanged: (v) => widget.onParameterChanged(
                                        'filterCutoff', v),
                                    paramId: 'filterCutoff',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                  _knob(
                                    label: 'Res',
                                    value: widget.device.filterQ,
                                    size: filterKnob,
                                    labelGap: 1,
                                    displayValue: SamplerDevicePanel.formatQ(
                                        widget.device.filterQ),
                                    onChanged: (v) =>
                                        widget.onParameterChanged('filterQ', v),
                                    paramId: 'filterQ',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                  _knob(
                                    label: 'Env',
                                    value: widget.device.filterEnvAmount,
                                    size: filterKnob,
                                    labelGap: 1,
                                    displayValue:
                                        SamplerDevicePanel.formatPercent(
                                      widget.device.filterEnvAmount,
                                    ),
                                    onChanged: (v) => widget.onParameterChanged(
                                        'filterEnvAmount', v),
                                    paramId: 'filterEnvAmount',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                  _knob(
                                    label: 'FM',
                                    value: widget.device.filterFm,
                                    size: filterKnob,
                                    labelGap: 1,
                                    displayValue:
                                        SamplerDevicePanel.formatPercent(
                                      widget.device.filterFm,
                                    ),
                                    onChanged: (v) => widget.onParameterChanged(
                                        'filterFm', v),
                                    paramId: 'filterFm',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 1,
                  child: _panelBox(
                    variant: PanelVariant.subtle,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'COLOR',
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
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _knob(
                                      label: 'Drive',
                                      value: widget.device.filterDrive,
                                      size: colorKnob,
                                      labelGap: 1,
                                      displayValue:
                                          SamplerDevicePanel.formatPercent(
                                              widget.device.filterDrive),
                                      onChanged: (v) => widget
                                          .onParameterChanged('filterDrive', v),
                                      paramId: 'filterDrive',
                                      modulationAmounts:
                                          widget.modulationAmounts,
                                      connectModeLfoId: widget.connectModeLfoId,
                                      onModulationAssign:
                                          widget.onModulationAssign,
                                    ),
                                    _knob(
                                      label: 'Shaper',
                                      value: widget.device.filterShaper,
                                      size: colorKnob,
                                      labelGap: 1,
                                      displayValue:
                                          SamplerDevicePanel.formatPercent(
                                              widget.device.filterShaper),
                                      onChanged: (v) =>
                                          widget.onParameterChanged(
                                              'filterShaper', v),
                                      paramId: 'filterShaper',
                                      modulationAmounts:
                                          widget.modulationAmounts,
                                      connectModeLfoId: widget.connectModeLfoId,
                                      onModulationAssign:
                                          widget.onModulationAssign,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: SizedBox(
                            width: 52,
                            height: 22,
                            child: _borderlessDropdown<int>(
                              value: shaperMode,
                              items: List.generate(
                                SubtractiveSynthDevicePanel._shaperModes.length,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    SubtractiveSynthDevicePanel._shaperModes[i],
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ),
                              ),
                              onChanged: (v) {
                                if (v != null) {
                                  widget.onParameterChanged(
                                      'filterShaperMode', v.toDouble());
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _oscKnobGridRow({
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

  Widget _flatToggle({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? SubtractiveSynthDevicePanel.accent : Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _oscSelectorButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.22)
          : Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? SubtractiveSynthDevicePanel.accent
                  : Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterKeyTrackToggle() {
    final active = widget.device.filterKeyTrack > 0.001;
    final color = active ? SubtractiveSynthDevicePanel.accent : Colors.white38;
    return Padding(
      padding: const EdgeInsets.only(top: 13),
      child: Tooltip(
        message: active
            ? 'Keyboard tracking affects filter cutoff'
            : 'Enable keyboard tracking for filter cutoff',
        child: Material(
          color: active
              ? SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            onTap: () => widget.onParameterChanged(
              'filterKeyTrack',
              active ? 0.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(5),
            child: SizedBox.square(
              dimension: 30,
              child: Icon(Icons.piano, size: 20, color: color),
            ),
          ),
        ),
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
        icon: const Icon(Icons.expand_more,
            color: SubtractiveSynthDevicePanel.accent, size: 14),
        items: items,
        onChanged: onChanged,
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
    double? knobScale,
    double spacing = 8,
    double labelGap = 1,
  }) {
    final size = knobScale ?? _knobSize * 0.8;
    String id(String name) => prefix.isEmpty
        ? name
        : '$prefix${name[0].toUpperCase()}${name.substring(1)}';
    final aId = id('attack');
    final dId = id('decay');
    final sId = id('sustain');
    final rId = id('release');
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _knob(
            label: 'A',
            value: attack,
            size: size,
            labelGap: labelGap,
            displayValue: SamplerDevicePanel.formatPercent(attack),
            onChanged: (v) => onChanged(aId, v),
            paramId: aId,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'D',
            value: decay,
            size: size,
            labelGap: labelGap,
            displayValue: SamplerDevicePanel.formatPercent(decay),
            onChanged: (v) => onChanged(dId, v),
            paramId: dId,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'S',
            value: sustain,
            size: size,
            labelGap: labelGap,
            displayValue: SamplerDevicePanel.formatPercent(sustain),
            onChanged: (v) => onChanged(sId, v),
            paramId: sId,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'R',
            value: release,
            size: size,
            labelGap: labelGap,
            displayValue: SamplerDevicePanel.formatPercent(release),
            onChanged: (v) => onChanged(rId, v),
            paramId: rId,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
      ],
    );
  }
}
