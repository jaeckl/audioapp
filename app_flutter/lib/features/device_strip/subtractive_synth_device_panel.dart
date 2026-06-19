import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'draggable_int_value_box.dart';
import 'rotary_knob.dart';
import 'sampler_device_panel.dart';
import 'stereo_gain_pan_panel.dart';
import 'subtractive_filter_preview.dart';
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
    this.modulatedParams = const {},
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
    DeviceTabSpec(label: 'Filter', icon: Icons.tune),
    DeviceTabSpec(label: 'Amp', icon: Icons.show_chart),
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
              paramId: shapeParam,
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            _knob(
              label: 'Pitch',
              value: semi,
              size: _knobSize * 0.82,
              displayValue: '${(semi * 11).round()}',
              onChanged: (v) => widget.onParameterChanged(semiParam, v),
              paramId: semiParam,
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            _knob(
              label: 'Sync',
              value: sync,
              size: _knobSize * 0.82,
              displayValue: SamplerDevicePanel.formatPercent(sync),
              onChanged: (v) => widget.onParameterChanged(syncParam, v),
              paramId: syncParam,
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
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
    final knobScale = _knobSize * 0.78;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mixColumn(
            title: 'UNISON',
            row1: _knob(
              label: 'Voices',
              value: widget.device.unisonVoices,
              size: knobScale,
              displayValue: '${1 + (widget.device.unisonVoices * 3).round()}',
              onChanged: (v) => widget.onParameterChanged('unisonVoices', v),
              paramId: 'unisonVoices',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            row2: _knob(
              label: 'Spread',
              value: widget.device.unisonDetune,
              size: knobScale,
              displayValue: SamplerDevicePanel.formatPercent(widget.device.unisonDetune),
              onChanged: (v) => widget.onParameterChanged('unisonDetune', v),
              paramId: 'unisonDetune',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            row3: _knob(
              label: 'Fine',
              value: widget.device.osc2Detune,
              size: knobScale,
              displayValue:
                  '${((widget.device.osc2Detune - 0.5) * 100).round()}¢',
              onChanged: (v) => widget.onParameterChanged('osc2Detune', v),
              paramId: 'osc2Detune',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
          ),
          const SizedBox(width: 6),
          _mixColumn(
            title: 'MIXER',
            row1: _borderlessDropdown<int>(
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
            row2: _knob(
              label: 'Mix',
              value: widget.device.oscMix,
              size: knobScale,
              displayValue: SamplerDevicePanel.formatPercent(widget.device.oscMix),
              onChanged: (v) => widget.onParameterChanged('oscMix', v),
              paramId: 'oscMix',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            row3: _knob(
              label: 'Noise',
              value: widget.device.noiseLevel,
              size: knobScale,
              displayValue: SamplerDevicePanel.formatPercent(widget.device.noiseLevel),
              onChanged: (v) => widget.onParameterChanged('noiseLevel', v),
              paramId: 'noiseLevel',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
          ),
          const SizedBox(width: 6),
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
              displayValue: SubtractiveSynthDevicePanel.formatGlobalPitch(widget.device.globalPitch),
              onChanged: (v) => widget.onParameterChanged('globalPitch', v),
              paramId: 'globalPitch',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            row2: _knob(
              label: 'Glide',
              value: widget.device.glideMs,
              size: knobScale,
              displayValue: widget.device.glideMs <= 0.001
                  ? 'Off'
                  : '${(widget.device.glideMs * 2000).round()} ms',
              onChanged: (v) => widget.onParameterChanged('glideMs', v),
              paramId: 'glideMs',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            row3: _knob(
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
            const SizedBox(height: 2),
            Expanded(child: Center(child: row1)),
            Expanded(child: Center(child: row2)),
            Expanded(child: Center(child: row3)),
          ],
        ),
      ),
    );
  }

  Widget _filterTab() {
    final mode = widget.device.filterMode.clamp(0, SubtractiveSynthDevicePanel._filterTypes.length - 1);
    final shaperMode =
        widget.device.filterShaperMode.clamp(0, SubtractiveSynthDevicePanel._shaperModes.length - 1);
    final compactKnob = _knobSize * 0.68;
    final fegKnob = _knobSize * 0.7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 24,
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
            flex: 6,
            child: _panelBox(
              variant: PanelVariant.elevated,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                    SizedBox(
                      width: compactKnob + 10,
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
                          if (v != null) widget.onParameterChanged('filterMode', v.toDouble());
                        },
                      ),
                    ),
                    _knob(
                      label: 'Cutoff',
                      value: widget.device.filterCutoff,
                      size: compactKnob,
                      labelGap: 1,
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
                      size: compactKnob,
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
                      size: compactKnob,
                      displayValue: SamplerDevicePanel.formatPercent(widget.device.filterKeyTrack),
                      onChanged: (v) => widget.onParameterChanged('filterKeyTrack', v),
                      paramId: 'filterKeyTrack',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                    _knob(
                      label: 'FM',
                      value: widget.device.filterFm,
                      size: compactKnob,
                      displayValue: SamplerDevicePanel.formatPercent(widget.device.filterFm),
                      onChanged: (v) => widget.onParameterChanged('filterFm', v),
                      paramId: 'filterFm',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _knob(
                      label: 'Drive',
                      value: widget.device.filterDrive,
                      size: compactKnob,
                      displayValue: SamplerDevicePanel.formatPercent(widget.device.filterDrive),
                      onChanged: (v) => widget.onParameterChanged('filterDrive', v),
                      paramId: 'filterDrive',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                    _knob(
                      label: 'Shaper',
                      value: widget.device.filterShaper,
                      size: compactKnob,
                      displayValue: SamplerDevicePanel.formatPercent(widget.device.filterShaper),
                      onChanged: (v) => widget.onParameterChanged('filterShaper', v),
                      paramId: 'filterShaper',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                    SizedBox(
                      width: compactKnob + 6,
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
                    _knob(
                      label: 'FEG',
                      value: widget.device.filterEnvAmount,
                      size: compactKnob,
                      displayValue: SamplerDevicePanel.formatPercent(widget.device.filterEnvAmount),
                      onChanged: (v) => widget.onParameterChanged('filterEnvAmount', v),
                      paramId: 'filterEnvAmount',
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
          const SizedBox(height: 4),
          Expanded(
            flex: 4,
            child: _panelBox(
              variant: PanelVariant.screen,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Center(
                child: _adsrRow(
                  attack: widget.device.filterAttack,
                  decay: widget.device.filterDecay,
                  sustain: widget.device.filterSustain,
                  release: widget.device.filterRelease,
                  onChanged: (id, v) => widget.onParameterChanged(id, v),
                  prefix: 'filter',
                  knobScale: fegKnob,
                  spacing: 6,
                  labelGap: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.22)
              : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active
                ? SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? SubtractiveSynthDevicePanel.accent : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
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

  Widget _ampTab() {
    final knobScale = _knobSize * 0.78;
    final aegKnob = _knobSize * 0.7;
    final legatoOn = widget.device.synthLegato >= 0.5;
    final monoOn = widget.device.synthMono >= 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: _panelBox(
              variant: PanelVariant.elevated,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _knob(
                        label: 'Velocity',
                        value: widget.device.velocitySensitivity,
                        size: knobScale,
                        labelGap: 1,
                        displayValue: SamplerDevicePanel.formatPercent(widget.device.velocitySensitivity),
                        onChanged: (v) => widget.onParameterChanged('velocitySensitivity', v),
                        paramId: 'velocitySensitivity',
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'Pan',
                        value: widget.device.pan,
                        size: knobScale,
                        labelGap: 1,
                        displayValue: StereoGainPanPanel.formatPan(widget.device.pan),
                        onChanged: (v) => widget.onParameterChanged('pan', v),
                        paramId: 'pan',
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _modeChip(
                        label: 'Legato',
                        active: legatoOn,
                        onTap: () => widget.onParameterChanged('synthLegato', legatoOn ? 0.0 : 1.0),
                      ),
                      const SizedBox(width: 10),
                      _modeChip(
                        label: 'Mono',
                        active: monoOn,
                        onTap: () => widget.onParameterChanged('synthMono', monoOn ? 0.0 : 1.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 5,
            child: _panelBox(
              variant: PanelVariant.screen,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Center(
                child: _adsrRow(
                  attack: widget.device.attack,
                  decay: widget.device.decay,
                  sustain: widget.device.sustain,
                  release: widget.device.release,
                  onChanged: widget.onParameterChanged,
                  knobScale: aegKnob,
                  spacing: 6,
                  labelGap: 1,
                ),
              ),
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

