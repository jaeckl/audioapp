import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart' show DeviceTabSpec;
import 'modulator_polarity.dart';
import 'sampler_envelope_preview.dart';
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

  final DeviceSnapshot device;
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

  final DeviceSnapshot device;
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

  final DeviceSnapshot device;
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

  static const _filterModes = ['LP', 'HP', 'BP', 'NT'];

  Widget _knob({
    required String label,
    required String paramId,
    required double value,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return deviceAutomationKnob(
      label: label,
      value: value,
      size: knobSize,
      displayValue: displayValue,
      onChanged: onChanged,
      paramId: paramId,
      accentColor: SamplerDevicePanel.accent,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeIndex = device.filterMode.clamp(0, _filterModes.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF121218),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SamplerEnvelopePreview(
                attack: device.attack,
                decay: device.decay,
                sustain: device.sustain,
                release: device.release,
                accent: SamplerDevicePanel.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _KnobRow(
          children: [
            _knob(
              label: 'Attack',
              paramId: 'attack',
              value: device.attack,
              displayValue: SamplerDevicePanel.formatPercent(device.attack),
              onChanged: (v) => onParameterChanged('attack', v),
            ),
            _knob(
              label: 'Decay',
              paramId: 'decay',
              value: device.decay,
              displayValue: SamplerDevicePanel.formatPercent(device.decay),
              onChanged: (v) => onParameterChanged('decay', v),
            ),
            _knob(
              label: 'Sustain',
              paramId: 'sustain',
              value: device.sustain,
              displayValue: SamplerDevicePanel.formatPercent(device.sustain),
              onChanged: (v) => onParameterChanged('sustain', v),
            ),
            _knob(
              label: 'Release',
              paramId: 'release',
              value: device.release,
              displayValue: SamplerDevicePanel.formatPercent(device.release),
              onChanged: (v) => onParameterChanged('release', v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF121218),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_filterModes.length, (index) {
                      final selected = index == modeIndex;
                      return InkWell(
                        onTap: () => onParameterChanged('filterMode', index.toDouble()),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 36,
                          height: editor ? 28 : 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? SamplerDevicePanel.accent.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: selected
                                  ? SamplerDevicePanel.accent.withValues(alpha: 0.7)
                                  : Colors.white12,
                            ),
                          ),
                          child: Text(
                            _filterModes[index],
                            style: TextStyle(
                              color: selected ? SamplerDevicePanel.accent : Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KnobRow(
                  children: [
                    _knob(
                      label: 'Cutoff',
                      paramId: 'filterCutoff',
                      value: device.filterCutoff,
                      displayValue: SamplerDevicePanel.formatCutoffHz(device.filterCutoff),
                      onChanged: (v) => onParameterChanged('filterCutoff', v),
                    ),
                    _knob(
                      label: 'Resonance',
                      paramId: 'filterQ',
                      value: device.filterQ,
                      displayValue: SamplerDevicePanel.formatQ(device.filterQ),
                      onChanged: (v) => onParameterChanged('filterQ', v),
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
}

class _KnobRow extends StatelessWidget {
  const _KnobRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

/// Collapsed strip summary — waveform peek.
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
