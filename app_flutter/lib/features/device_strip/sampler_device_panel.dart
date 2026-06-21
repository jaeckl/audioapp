import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart' show DeviceTabSpec;
import 'modulator_polarity.dart';
import 'sampler_envelope_preview.dart';
import 'sampler_filter_mode_icons.dart';
import 'sampler_waveform_view.dart';

/// Layout density for sampler controls.
enum SamplerPanelDensity { strip, editor }

enum SamplerDeviceTab { wave, tone }

/// Tabbed sampler UI — Wave (sample + playback) and Tone (env + filter).
class SamplerDevicePanel extends StatefulWidget {
  const SamplerDevicePanel({
    super.key,
    required this.device,
    required this.sample,
    required this.onParameterChanged,
    this.density = SamplerPanelDensity.strip,
    this.onPreview,
    this.onLoadSample,
    this.initialTab = SamplerDeviceTab.wave,
    this.onTabChanged,
    this.onCollapse,
    this.embeddedInCard = false,
    this.selectedTab,
    this.bpm = 120,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.lfos = const [],
    this.modEdges = const [],
  });

  final SamplerDeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final void Function(String parameterId, double value) onParameterChanged;
  final SamplerPanelDensity density;
  final VoidCallback? onPreview;
  final VoidCallback? onLoadSample;
  final SamplerDeviceTab initialTab;
  final ValueChanged<SamplerDeviceTab>? onTabChanged;
  final VoidCallback? onCollapse;
  final bool embeddedInCard;
  final SamplerDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final int bpm;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = Color(0xFFE8A54B);
  static const Color wave = Color(0xFF6EC9A0);

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Wave', icon: Icons.graphic_eq),
    DeviceTabSpec(label: 'Tone', icon: Icons.tune),
  ];

  static String formatCutoffHz(double normalized) {
    const minHz = 20.0;
    const maxHz = 20000.0;
    final hz = minHz * math.pow(maxHz / minHz, normalized.clamp(0, 1));
    if (hz >= 10000) {
      return '${(hz / 1000).toStringAsFixed(1)} kHz';
    }
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(2)} kHz';
    }
    return '${hz.round()} Hz';
  }

  static String formatQ(double normalized) {
    final q = 0.1 + normalized.clamp(0, 1) * 9.9;
    return q.toStringAsFixed(1);
  }

  static String formatPercent(double normalized) => '${(normalized * 100).round()}%';

  double get _knobSize => density == SamplerPanelDensity.editor
      ? DeviceKnobSizes.editor
      : DeviceKnobSizes.strip;

  bool get _isEditor => density == SamplerPanelDensity.editor;

  @override
  State<SamplerDevicePanel> createState() => _SamplerDevicePanelState();
}

class _SamplerDevicePanelState extends State<SamplerDevicePanel> {
  late SamplerDeviceTab _tab;

  SamplerDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  double get _durationSec {
    final beats = widget.sample?.durationBeats ?? 0;
    if (beats <= 0 || widget.bpm <= 0) return 1.0;
    return beats * 60.0 / widget.bpm;
  }

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant SamplerDevicePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTab != null && widget.selectedTab != oldWidget.selectedTab) {
      _tab = widget.selectedTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final peaks = widget.sample?.waveformPeaks ?? const <double>[];

    return Material(
      color: widget.embeddedInCard ? Colors.transparent : SamplerDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.embeddedInCard ? 10 : 12,
          widget.embeddedInCard ? 4 : 8,
          10,
          6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildTabBody(peaks)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(List<double> peaks) {
    switch (_activeTab) {
      case SamplerDeviceTab.wave:
        return _WaveTab(
          device: widget.device,
          sampleName: widget.sample?.name,
          peaks: peaks,
          durationSec: _durationSec,
          onParameterChanged: widget.onParameterChanged,
          onPreview: widget.onPreview,
          onLoadSample: widget.onLoadSample,
          modulatedParams: widget.modulatedParams,
          automatedParams: widget.automatedParams,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
          automationLinkActive: widget.automationLinkActive,
          onAutomationLinkTap: widget.onAutomationLinkTap,
          onAutomateParameter: widget.onAutomateParameter,
          lfos: widget.lfos,
          modEdges: widget.modEdges,
        );
      case SamplerDeviceTab.tone:
        return _ToneTab(
          device: widget.device,
          knobSize: widget._knobSize,
          editor: widget._isEditor,
          onParameterChanged: widget.onParameterChanged,
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
  }
}

class _WaveTab extends StatelessWidget {
  const _WaveTab({
    required this.device,
    required this.sampleName,
    required this.peaks,
    required this.durationSec,
    required this.onParameterChanged,
    this.onPreview,
    this.onLoadSample,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
    this.lfos = const [],
    this.modEdges = const [],
  });

  final SamplerDeviceSnapshot device;
  final String? sampleName;
  final List<double> peaks;
  final double durationSec;
  final void Function(String parameterId, double value) onParameterChanged;
  final VoidCallback? onPreview;
  final VoidCallback? onLoadSample;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;

  SpinnerModulationProps get _spinnerModulation => SpinnerModulationProps(
        modulatedParams: modulatedParams,
        automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
        rootPitchPolarity: modulatorPolarityForParam(
          paramId: 'rootPitch',
          deviceId: device.id,
          modEdges: modEdges,
          lfos: lfos,
          connectModeLfoId: connectModeLfoId,
        ),
        rootFineTunePolarity: modulatorPolarityForParam(
          paramId: 'rootFineTune',
          deviceId: device.id,
          modEdges: modEdges,
          lfos: lfos,
          connectModeLfoId: connectModeLfoId,
        ),
      );

  void _setPlaybackMode(int mode) {
    onParameterChanged('playbackMode', mode.toDouble());
    if (mode == 1 && device.regionEndSec <= 0) {
      final dur = durationSec > 0 ? durationSec : 1.0;
      onParameterChanged('regionStartSec', 0);
      onParameterChanged('regionEndSec', (dur * 0.25).clamp(0.05, dur));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF121218),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SamplerWaveformView(
                  peaks: peaks,
                  durationSec: durationSec,
                  trimStartSec: device.trimStartSec,
                  trimEndSec: device.trimEndSec,
                  regionStartSec: device.regionStartSec,
                  regionEndSec: device.regionEndSec,
                  density: SamplerWaveformDensity.editor,
                  waveColor: SamplerDevicePanel.wave,
                  accentColor: SamplerDevicePanel.accent,
                  loopRegionEnabled: device.playbackMode == 1,
                  onPreview: peaks.isEmpty ? null : onPreview,
                  onLoadSample: onLoadSample,
                  onTrimChanged: (start, end) {
                    onParameterChanged('trimStartSec', start);
                    onParameterChanged('trimEndSec', end);
                  },
                  onRegionChanged: device.playbackMode == 1
                      ? (start, end) {
                          onParameterChanged('regionStartSec', start);
                          onParameterChanged('regionEndSec', end);
                        }
                      : null,
                  emptyHint: 'Choose a sample from your library or import audio',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: onLoadSample == null
                  ? Text(
                      sampleName ?? 'No sample',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onLoadSample,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sampleName ?? 'No sample',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.folder_open_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.38),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            if (peaks.isNotEmpty)
              Text(
                formatSamplerPlaybackRange(
                  playbackMode: device.playbackMode,
                  durationSec: durationSec,
                  trimStartSec: device.trimStartSec,
                  trimEndSec: device.trimEndSec,
                  regionStartSec: device.regionStartSec,
                  regionEndSec: device.regionEndSec,
                ),
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SamplerPlaybackIdentityBar(
          rootPitch: device.rootPitch.round(),
          rootFineTune: device.rootFineTune,
          playbackMode: device.playbackMode,
          accentColor: SamplerDevicePanel.accent,
          previewEnabled: peaks.isNotEmpty,
          onRootPitchChanged: (pitch) => onParameterChanged('rootPitch', pitch.toDouble()),
          onRootFineTuneChanged: (cents) => onParameterChanged('rootFineTune', cents),
          onPlaybackModeChanged: _setPlaybackMode,
          onPreview: onPreview,
          modulation: _spinnerModulation,
        ),
      ],
    );
  }
}

class _ToneTab extends StatelessWidget {
  const _ToneTab({
    required this.device,
    required this.knobSize,
    required this.editor,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.onModulationAssign,
    required this.automationLinkActive,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final SamplerDeviceSnapshot device;
  final double knobSize;
  final bool editor;
  final void Function(String parameterId, double value) onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const _toneCellDecoration = BoxDecoration(
    color: Color(0xFF121218),
    borderRadius: BorderRadius.all(Radius.circular(6)),
    border: Border.fromBorderSide(BorderSide(color: Color(0x14FFFFFF))),
  );

  Widget _knob({
    required String label,
    required String paramId,
    required double value,
    required String displayValue,
    required ValueChanged<double> onChanged,
    double? size,
    bool showLabel = true,
    double labelGap = 3,
    Color accentColor = SamplerDevicePanel.accent,
  }) {
    return deviceAutomationKnob(
      label: label,
      value: value,
      size: size ?? knobSize,
      displayValue: displayValue,
      onChanged: onChanged,
      paramId: paramId,
      accentColor: accentColor,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
      showLabel: showLabel,
      labelGap: labelGap,
    );
  }

  Widget _toneCell({required Widget child, EdgeInsets padding = const EdgeInsets.all(4)}) {
    return DecoratedBox(
      decoration: _toneCellDecoration,
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _previewCell(SamplerEnvelopePreview preview) {
    return _toneCell(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: IgnorePointer(
          child: preview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeIndex = device.filterMode.clamp(0, 3);
    final maxFilterKnob = editor ? DeviceKnobSizes.editor : DeviceKnobSizes.strip;
    final leftWidth = editor ? 88.0 : 78.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: leftWidth,
          child: _toneCell(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: SamplerFilterModeBar(
                    selectedIndex: modeIndex,
                    accentColor: SamplerDevicePanel.accent,
                    onSelected: (index) => onParameterChanged('filterMode', index.toDouble()),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _filterKnobSlot(
                    maxKnob: maxFilterKnob,
                    label: 'Cutoff',
                    paramId: 'filterCutoff',
                    value: device.filterCutoff,
                    displayValue: SamplerDevicePanel.formatCutoffHz(device.filterCutoff),
                    onChanged: (v) => onParameterChanged('filterCutoff', v),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _filterKnobSlot(
                    maxKnob: maxFilterKnob,
                    label: 'Res',
                    paramId: 'filterQ',
                    value: device.filterQ,
                    displayValue: SamplerDevicePanel.formatQ(device.filterQ),
                    onChanged: (v) => onParameterChanged('filterQ', v),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _filterKnobSlot(
                    maxKnob: maxFilterKnob,
                    label: 'FEG',
                    paramId: 'filterEnvAmount',
                    value: device.filterEnvAmount,
                    displayValue: SamplerDevicePanel.formatPercent(device.filterEnvAmount),
                    onChanged: (v) => onParameterChanged('filterEnvAmount', v),
                    accentColor: SamplerDevicePanel.wave,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _previewCell(
                  SamplerEnvelopePreview(
                    attack: device.attack,
                    decay: device.decay,
                    sustain: device.sustain,
                    release: device.release,
                    accent: SamplerDevicePanel.accent,
                    label: 'AEG',
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                flex: 8,
                child: _toneCell(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: _buildAdsrPanel(editor),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                flex: 3,
                child: _previewCell(
                  SamplerEnvelopePreview(
                    attack: device.filterAttack,
                    decay: device.filterDecay,
                    sustain: device.filterSustain,
                    release: device.filterRelease,
                    accent: SamplerDevicePanel.wave,
                    label: 'FEG',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterKnobSlot({
    required double maxKnob,
    required String label,
    required String paramId,
    required double value,
    required String displayValue,
    required ValueChanged<double> onChanged,
    Color accentColor = SamplerDevicePanel.accent,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final knobSize = math.min(constraints.maxHeight, constraints.maxWidth).clamp(28.0, maxKnob);
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _knob(
              label: label,
              paramId: paramId,
              value: value,
              displayValue: displayValue,
              onChanged: onChanged,
              size: knobSize,
              labelGap: 1,
              accentColor: accentColor,
            ),
          ),
        );
      },
    );
  }

  /// Amp + filter ADSR rows with shared A/D/S/R labels centered between them.
  Widget _buildAdsrPanel(bool editor) {
    const labels = ['A', 'D', 'S', 'R'];
    const labelStripHeight = 14.0;
    final maxKnob = editor ? DeviceKnobSizes.editor : DeviceKnobSizes.strip;

    final aegKnobs = <({String paramId, double value, String display, ValueChanged<double> onChanged})>[
      (
        paramId: 'attack',
        value: device.attack,
        display: SamplerDevicePanel.formatPercent(device.attack),
        onChanged: (v) => onParameterChanged('attack', v),
      ),
      (
        paramId: 'decay',
        value: device.decay,
        display: SamplerDevicePanel.formatPercent(device.decay),
        onChanged: (v) => onParameterChanged('decay', v),
      ),
      (
        paramId: 'sustain',
        value: device.sustain,
        display: SamplerDevicePanel.formatPercent(device.sustain),
        onChanged: (v) => onParameterChanged('sustain', v),
      ),
      (
        paramId: 'release',
        value: device.release,
        display: SamplerDevicePanel.formatPercent(device.release),
        onChanged: (v) => onParameterChanged('release', v),
      ),
    ];

    final fegKnobs = <({String paramId, double value, String display, ValueChanged<double> onChanged})>[
      (
        paramId: 'filterAttack',
        value: device.filterAttack,
        display: SamplerDevicePanel.formatPercent(device.filterAttack),
        onChanged: (v) => onParameterChanged('filterAttack', v),
      ),
      (
        paramId: 'filterDecay',
        value: device.filterDecay,
        display: SamplerDevicePanel.formatPercent(device.filterDecay),
        onChanged: (v) => onParameterChanged('filterDecay', v),
      ),
      (
        paramId: 'filterSustain',
        value: device.filterSustain,
        display: SamplerDevicePanel.formatPercent(device.filterSustain),
        onChanged: (v) => onParameterChanged('filterSustain', v),
      ),
      (
        paramId: 'filterRelease',
        value: device.filterRelease,
        display: SamplerDevicePanel.formatPercent(device.filterRelease),
        onChanged: (v) => onParameterChanged('filterRelease', v),
      ),
    ];

    Widget knobRow({
      required double knobSize,
      required List<({String paramId, double value, String display, ValueChanged<double> onChanged})> specs,
      Color accentColor = SamplerDevicePanel.accent,
    }) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final fitSize = math
              .min(
                knobSize,
                math.min(constraints.maxHeight - 2, constraints.maxWidth / 4 - 2),
              )
              .clamp(28.0, maxKnob);
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final spec in specs)
                    _knob(
                      label: spec.paramId,
                      paramId: spec.paramId,
                      value: spec.value,
                      displayValue: spec.display,
                      onChanged: spec.onChanged,
                      size: fitSize,
                      showLabel: false,
                      accentColor: accentColor,
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = (constraints.maxHeight - labelStripHeight) / 2;
        final colWidth = constraints.maxWidth / 4;
        final knobSize = (math.min(rowHeight, colWidth) - 6).clamp(28.0, maxKnob);

        return ClipRect(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: rowHeight,
                child: knobRow(knobSize: knobSize, specs: aegKnobs),
              ),
              const SizedBox(
                height: labelStripHeight,
                child: _AdsrLabelStrip(labels: labels),
              ),
              SizedBox(
                height: rowHeight,
                child: knobRow(knobSize: knobSize, specs: fegKnobs, accentColor: SamplerDevicePanel.wave),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdsrLabelStrip extends StatelessWidget {
  const _AdsrLabelStrip({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class SamplerDeviceStripCollapsed extends StatelessWidget {
  const SamplerDeviceStripCollapsed({
    super.key,
    required this.sample,
    required this.onExpand,
    this.embeddedInCard = false,
  });

  final SampleLibraryEntrySnapshot? sample;
  final VoidCallback onExpand;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    final peaks = sample?.waveformPeaks ?? const <double>[];

    return Material(
      color: embeddedInCard ? Colors.transparent : SamplerDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(embeddedInCard ? 10 : 0, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121218),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: peaks.isEmpty
                      ? null
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: CustomPaint(
                            painter: WaveformPainter(
                              peaks: peaks,
                              color: SamplerDevicePanel.wave,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Expand device',
              visualDensity: VisualDensity.compact,
              onPressed: onExpand,
              icon: const Icon(Icons.unfold_more, size: 20, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
