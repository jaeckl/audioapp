import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'draggable_int_value_box.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'subtractive_filter_preview.dart';
import 'subtractive_waveform_preview.dart';

enum SubtractivePanelDensity { strip, editor }

/// Three-tab strip: Osc · Mix · Tone (filter + amp merged).
/// Four-tab layout preserved in git at commit before the 3-tab redesign.
enum SubtractiveDeviceTab { osc, mix, tone }

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
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
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
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = DeviceStripTheme.subtractiveSynthAccent;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Osc', icon: Icons.waves),
    DeviceTabSpec(label: 'Mix', icon: Icons.blender),
    DeviceTabSpec(label: 'Tone', icon: Icons.tune),
  ];

  static const _mixModes = ['Mix', 'Neg', 'AM', 'Sign', 'Max'];
  static const _filterTypes = ['LP 12', 'HP 12', 'Band', 'Notch', 'FB', 'LP 24'];
  static const _shaperModes = ['Off', 'Soft', 'Hard', 'Fold'];

  static String formatGlobalPitch(double normalized) {
    final st = ((normalized - 0.5) * 24).round();
    if (st == 0) return '0';
    return st > 0 ? '+$st' : '$st';
  }

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
      SubtractiveDeviceTab.tone => _toneTab(),
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
    final knobScale = _knobSize * 0.72;
    final legatoOn = widget.device.synthLegato >= 0.5;
    final monoOn = widget.device.synthMono >= 0.5;
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
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _oscBank(
                          label: 'Osc 1',
                          shape: widget.device.osc1Shape,
                          shapeParam: 'osc1Shape',
                          semi: widget.device.osc1Semi,
                          semiParam: 'osc1Semi',
                          octaveNorm: widget.device.osc1Octave,
                          octaveParam: 'osc1Octave',
                          syncValue: widget.device.osc1Sync,
                          syncParam: 'osc1Sync',
                          syncDisplay:
                              SamplerDevicePanel.formatPercent(widget.device.osc1Sync),
                          knobScale: knobScale,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _oscBank(
                          label: 'Osc 2',
                          shape: widget.device.osc2Shape,
                          shapeParam: 'osc2Shape',
                          semi: widget.device.osc2Semi,
                          semiParam: 'osc2Semi',
                          octaveNorm: widget.device.osc2Octave,
                          octaveParam: 'osc2Octave',
                          syncValue: widget.device.osc2Sync,
                          syncParam: 'osc2Sync',
                          syncDisplay:
                              SamplerDevicePanel.formatPercent(widget.device.osc2Sync),
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
                const SizedBox(height: 4),
                _oscMixerRow(knobScale),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _panelBox(
                    variant: PanelVariant.elevated,
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
                        const SizedBox(height: 2),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size =
                                  (constraints.maxHeight - 18).clamp(18.0, knobScale * 0.88);
                              return Align(
                                alignment: Alignment.topCenter,
                                child: _knob(
                                  label: 'Voices',
                                  value: widget.device.unisonVoices,
                                  size: size,
                                  labelGap: 0,
                                  displayValue:
                                      '${1 + (widget.device.unisonVoices * 3).round()}',
                                  onChanged: (v) =>
                                      widget.onParameterChanged('unisonVoices', v),
                                  paramId: 'unisonVoices',
                                  modulationAmounts: widget.modulationAmounts,
                                  connectModeLfoId: widget.connectModeLfoId,
                                  onModulationAssign: widget.onModulationAssign,
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size =
                                  (constraints.maxHeight - 18).clamp(18.0, knobScale * 0.88);
                              return Align(
                                alignment: Alignment.topCenter,
                                child: _knob(
                                  label: 'Spread',
                                  value: widget.device.unisonDetune,
                                  size: size,
                                  labelGap: 0,
                                  displayValue: SamplerDevicePanel.formatPercent(
                                      widget.device.unisonDetune),
                                  onChanged: (v) =>
                                      widget.onParameterChanged('unisonDetune', v),
                                  paramId: 'unisonDetune',
                                  modulationAmounts: widget.modulationAmounts,
                                  connectModeLfoId: widget.connectModeLfoId,
                                  onModulationAssign: widget.onModulationAssign,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  flex: 4,
                  child: _panelBox(
                    variant: PanelVariant.subtle,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          'PLAY',
                          style: TextStyle(
                            color: Colors.white30,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _flatToggle(
                              label: 'Legato',
                              active: legatoOn,
                              onTap: () => widget.onParameterChanged(
                                  'synthLegato', legatoOn ? 0.0 : 1.0),
                            ),
                            const SizedBox(width: 4),
                            _flatToggle(
                              label: 'Mono clips',
                              active: monoOn,
                              onTap: () =>
                                  widget.onParameterChanged('synthMono', monoOn ? 0.0 : 1.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size =
                                  (constraints.maxHeight - 18).clamp(18.0, knobScale * 0.82);
                              return Align(
                                alignment: Alignment.topCenter,
                                child: _knob(
                                  label: 'Glide',
                                  value: widget.device.glideMs,
                                  size: size,
                                  labelGap: 0,
                                  displayValue: widget.device.glideMs <= 0.001
                                      ? 'Off'
                                      : '${(widget.device.glideMs * 2000).round()} ms',
                                  onChanged: (v) => widget.onParameterChanged('glideMs', v),
                                  paramId: 'glideMs',
                                  modulationAmounts: widget.modulationAmounts,
                                  connectModeLfoId: widget.connectModeLfoId,
                                  onModulationAssign: widget.onModulationAssign,
                                ),
                              );
                            },
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

  Widget _oscMixerRow(double knobScale) {
    return SizedBox(
      height: 66,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mixKnob = (constraints.maxHeight - 16).clamp(38.0, knobScale * 1.08);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'MIXER',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
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
                    if (v != null) widget.onParameterChanged('oscMixMode', v.toDouble());
                  },
                ),
              ),
              const Spacer(),
              _knob(
                label: 'Mix',
                value: widget.device.oscMix,
                size: mixKnob,
                labelGap: 0,
                displayValue: SamplerDevicePanel.formatPercent(widget.device.oscMix),
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
                size: mixKnob,
                labelGap: 0,
                displayValue: SamplerDevicePanel.formatPercent(widget.device.noiseLevel),
                onChanged: (v) => widget.onParameterChanged('noiseLevel', v),
                paramId: 'noiseLevel',
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }

  Widget _oscOctaveSlot({
    required double knobScale,
    required int octave,
    required String octaveParam,
  }) {
    const boxHeight = 28.0;
    final dialHeight = knobScale + 4;
    final topPad = (dialHeight - boxHeight) / 2;
    final bottomPad = topPad;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topPad),
        DraggableIntValueBox(
          value: octave,
          showLabel: false,
          accentColor: SubtractiveSynthDevicePanel.accent,
          onChanged: (v) => widget.onParameterChanged(
            octaveParam,
            subtractiveNormFromOctave(v),
          ),
        ),
        SizedBox(height: bottomPad),
        const Text(
          'Oct',
          style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600),
        ),
      ],
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
    required double syncValue,
    required String syncParam,
    required String syncDisplay,
    required double knobScale,
    double? detuneValue,
    String? detuneParam,
    String? detuneDisplay,
  }) {
    final octave = subtractiveOctaveFromNorm(octaveNorm);
    final hasDetune = detuneValue != null && detuneParam != null && detuneDisplay != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        SizedBox(
          height: 52,
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
          child: Column(
            children: [
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
                    _knob(
                      label: 'Pitch',
                      value: semi,
                      size: knobScale,
                      displayValue: '${(semi * 11).round()}',
                      onChanged: (v) => widget.onParameterChanged(semiParam, v),
                      paramId: semiParam,
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
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
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: SizedBox.shrink()),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: _oscOctaveSlot(
                          knobScale: knobScale,
                          octave: octave,
                          octaveParam: octaveParam,
                        ),
                      ),
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: hasDetune
                            ? _knob(
                                label: 'Detune',
                                value: detuneValue,
                                size: knobScale,
                                labelGap: 0,
                                displayValue: detuneDisplay,
                                onChanged: (v) =>
                                    widget.onParameterChanged(detuneParam, v),
                                paramId: detuneParam,
                                modulationAmounts: widget.modulationAmounts,
                                connectModeLfoId: widget.connectModeLfoId,
                                onModulationAssign: widget.onModulationAssign,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mixTab() {
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
                        : SamplerDevicePanel.formatCutoffHz(widget.device.preHpCutoff),
                    onChanged: (v) => widget.onParameterChanged('preHpCutoff', v),
                    paramId: 'preHpCutoff',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row2: _knob(
                    label: 'HP Res',
                    value: widget.device.preHpRes,
                    size: knobScale,
                    displayValue: SamplerDevicePanel.formatQ(widget.device.preHpRes),
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
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.preDrive),
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
                    displayValue:
                        SubtractiveSynthDevicePanel.formatGlobalPitch(widget.device.globalPitch),
                    onChanged: (v) => widget.onParameterChanged('globalPitch', v),
                    paramId: 'globalPitch',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row2: _knob(
                    label: 'FB',
                    value: widget.device.mixFeedback,
                    size: knobScale,
                    displayValue: SamplerDevicePanel.formatPercent(widget.device.mixFeedback),
                    onChanged: (v) => widget.onParameterChanged('mixFeedback', v),
                    paramId: 'mixFeedback',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row3: _knob(
                    label: 'Vel',
                    value: widget.device.velocitySensitivity,
                    size: knobScale,
                    displayValue:
                        SamplerDevicePanel.formatPercent(widget.device.velocitySensitivity),
                    onChanged: (v) => widget.onParameterChanged('velocitySensitivity', v),
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
    final mode = widget.device.filterMode.clamp(0, SubtractiveSynthDevicePanel._filterTypes.length - 1);
    final shaperMode =
        widget.device.filterShaperMode.clamp(0, SubtractiveSynthDevicePanel._shaperModes.length - 1);
    final filterKnob = _knobSize * 0.76;
    final colorKnob = _knobSize * 0.8;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 28,
            child: _panelBox(
              variant: PanelVariant.screen,
              padding: EdgeInsets.zero,
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
                  child: _panelBox(
                    variant: PanelVariant.elevated,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'FILTER',
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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _knob(
                                        label: 'Cutoff',
                                        value: widget.device.filterCutoff,
                                        size: filterKnob,
                                        labelGap: 1,
                                        displayValue: SamplerDevicePanel.formatCutoffHz(
                                          widget.device.filterCutoff,
                                        ),
                                        onChanged: (v) => widget.onParameterChanged('filterCutoff', v),
                                        paramId: 'filterCutoff',
                                        modulationAmounts: widget.modulationAmounts,
                                        connectModeLfoId: widget.connectModeLfoId,
                                        onModulationAssign: widget.onModulationAssign,
                                      ),
                                      _knob(
                                        label: 'Res',
                                        value: widget.device.filterQ,
                                        size: filterKnob,
                                        labelGap: 1,
                                        displayValue: SamplerDevicePanel.formatQ(widget.device.filterQ),
                                        onChanged: (v) => widget.onParameterChanged('filterQ', v),
                                        paramId: 'filterQ',
                                        modulationAmounts: widget.modulationAmounts,
                                        connectModeLfoId: widget.connectModeLfoId,
                                        onModulationAssign: widget.onModulationAssign,
                                      ),
                                      _knob(
                                        label: 'Key',
                                        value: widget.device.filterKeyTrack,
                                        size: filterKnob,
                                        labelGap: 1,
                                        displayValue: SamplerDevicePanel.formatPercent(
                                          widget.device.filterKeyTrack,
                                        ),
                                        onChanged: (v) =>
                                            widget.onParameterChanged('filterKeyTrack', v),
                                        paramId: 'filterKeyTrack',
                                        modulationAmounts: widget.modulationAmounts,
                                        connectModeLfoId: widget.connectModeLfoId,
                                        onModulationAssign: widget.onModulationAssign,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _knob(
                                        label: 'FEG',
                                        value: widget.device.filterEnvAmount,
                                        size: filterKnob,
                                        labelGap: 1,
                                        displayValue: SamplerDevicePanel.formatPercent(
                                          widget.device.filterEnvAmount,
                                        ),
                                        onChanged: (v) =>
                                            widget.onParameterChanged('filterEnvAmount', v),
                                        paramId: 'filterEnvAmount',
                                        modulationAmounts: widget.modulationAmounts,
                                        connectModeLfoId: widget.connectModeLfoId,
                                        onModulationAssign: widget.onModulationAssign,
                                      ),
                                      _knob(
                                        label: 'FM',
                                        value: widget.device.filterFm,
                                        size: filterKnob,
                                        labelGap: 1,
                                        displayValue:
                                            SamplerDevicePanel.formatPercent(widget.device.filterFm),
                                        onChanged: (v) => widget.onParameterChanged('filterFm', v),
                                        paramId: 'filterFm',
                                        modulationAmounts: widget.modulationAmounts,
                                        connectModeLfoId: widget.connectModeLfoId,
                                        onModulationAssign: widget.onModulationAssign,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: SizedBox(
                            width: 58,
                            height: 22,
                            child: _borderlessDropdown<int>(
                              value: mode,
                              items: List.generate(
                                SubtractiveSynthDevicePanel._filterTypes.length,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    SubtractiveSynthDevicePanel._filterTypes[i],
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ),
                              ),
                              onChanged: (v) {
                                if (v != null) {
                                  widget.onParameterChanged('filterMode', v.toDouble());
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _panelBox(
                    variant: PanelVariant.subtle,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _knob(
                                      label: 'Drive',
                                      value: widget.device.filterDrive,
                                      size: colorKnob,
                                      labelGap: 1,
                                      displayValue:
                                          SamplerDevicePanel.formatPercent(widget.device.filterDrive),
                                      onChanged: (v) => widget.onParameterChanged('filterDrive', v),
                                      paramId: 'filterDrive',
                                      modulationAmounts: widget.modulationAmounts,
                                      connectModeLfoId: widget.connectModeLfoId,
                                      onModulationAssign: widget.onModulationAssign,
                                    ),
                                    _knob(
                                      label: 'Shaper',
                                      value: widget.device.filterShaper,
                                      size: colorKnob,
                                      labelGap: 1,
                                      displayValue:
                                          SamplerDevicePanel.formatPercent(widget.device.filterShaper),
                                      onChanged: (v) => widget.onParameterChanged('filterShaper', v),
                                      paramId: 'filterShaper',
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
                                  widget.onParameterChanged('filterShaperMode', v.toDouble());
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
    String id(String name) => prefix.isEmpty ? name : '$prefix${name[0].toUpperCase()}${name.substring(1)}';
    final aId = id('attack');
    final dId = id('decay');
    final sId = id('sustain');
    final rId = id('release');
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _knob(label: 'A', value: attack, size: size, labelGap: labelGap,
          displayValue: SamplerDevicePanel.formatPercent(attack),
          onChanged: (v) => onChanged(aId, v),
          paramId: aId,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(label: 'D', value: decay, size: size, labelGap: labelGap,
          displayValue: SamplerDevicePanel.formatPercent(decay),
          onChanged: (v) => onChanged(dId, v),
          paramId: dId,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(label: 'S', value: sustain, size: size, labelGap: labelGap,
          displayValue: SamplerDevicePanel.formatPercent(sustain),
          onChanged: (v) => onChanged(sId, v),
          paramId: sId,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(label: 'R', value: release, size: size, labelGap: labelGap,
          displayValue: SamplerDevicePanel.formatPercent(release),
          onChanged: (v) => onChanged(rId, v),
          paramId: rId,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId),
      ],
    );
  }
}

