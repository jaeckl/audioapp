import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

/// Layout density for sampler controls.
enum SamplerPanelDensity { strip, editor }

enum SamplerDeviceTab { sample, env, filter }

/// Tabbed sampler UI — one parameter group per tab with large knobs (FLM / Note pattern).
class SamplerDevicePanel extends StatefulWidget {
  const SamplerDevicePanel({
    super.key,
    required this.device,
    required this.sample,
    required this.onParameterChanged,
    this.density = SamplerPanelDensity.strip,
    this.showExpandControl = false,
    this.onOpenFullscreen,
    this.initialTab = SamplerDeviceTab.sample,
    this.onTabChanged,
    this.onCollapse,
    this.embeddedInCard = false,
    this.selectedTab,
    this.modulatedParams = const {},
    this.onModulationAssign,
  });

  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final void Function(String parameterId, double value) onParameterChanged;
  final SamplerPanelDensity density;
  final bool showExpandControl;
  final VoidCallback? onOpenFullscreen;
  final SamplerDeviceTab initialTab;
  final ValueChanged<SamplerDeviceTab>? onTabChanged;
  final VoidCallback? onCollapse;
  final bool embeddedInCard;
  final SamplerDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final void Function(String paramId, String paramLabel)? onModulationAssign;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = Color(0xFFE8A54B);
  static const Color wave = Color(0xFF6EC9A0);

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Sample', icon: Icons.graphic_eq),
    DeviceTabSpec(label: 'Env', icon: Icons.show_chart),
    DeviceTabSpec(label: 'Filter', icon: Icons.tune),
  ];

  static const _tabs = containerTabs;

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

  @override
  State<SamplerDevicePanel> createState() => _SamplerDevicePanelState();
}

class _SamplerDevicePanelState extends State<SamplerDevicePanel> {
  late SamplerDeviceTab _tab;

  SamplerDeviceTab get _activeTab => widget.selectedTab ?? _tab;

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
    final theme = Theme.of(context);
    final sampleName = widget.sample?.name ?? 'No sample loaded';
    final peaks = widget.sample?.waveformPeaks ?? const <double>[];

    return Material(
      color: widget.embeddedInCard ? Colors.transparent : SamplerDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.embeddedInCard ? 10 : 0,
          widget.embeddedInCard ? 4 : 6,
          10,
          6,
        ),
        child: widget.embeddedInCard
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildTabBody(context, theme, peaks)),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: SamplerDevicePanel.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WaveformHeader(
                          sampleName: sampleName,
                          showExpandControl: widget.showExpandControl,
                          onOpenFullscreen: widget.onOpenFullscreen,
                          onCollapse: widget.onCollapse,
                        ),
                        const SizedBox(height: 6),
                        DeviceTabBar(
                          tabs: SamplerDevicePanel._tabs,
                          selectedIndex: _tab.index,
                          onSelected: (index) {
                            final tab = SamplerDeviceTab.values[index];
                            setState(() => _tab = tab);
                            widget.onTabChanged?.call(tab);
                          },
                          accentColor: SamplerDevicePanel.accent,
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _buildTabBody(context, theme, peaks)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBody(BuildContext context, ThemeData theme, List<double> peaks) {
    switch (_activeTab) {
      case SamplerDeviceTab.sample:
        return _SampleTab(
          peaks: peaks,
          showExpandControl: widget.embeddedInCard ? false : widget.showExpandControl,
          onOpenFullscreen: widget.onOpenFullscreen,
        );
      case SamplerDeviceTab.env:
        return _EnvTab(
          device: widget.device,
          knobSize: widget._knobSize,
          onParameterChanged: widget.onParameterChanged,
          modulatedParams: widget.modulatedParams,
          onModulationAssign: widget.onModulationAssign,
        );
      case SamplerDeviceTab.filter:
        return _FilterTab(
          device: widget.device,
          knobSize: widget._knobSize,
          onParameterChanged: widget.onParameterChanged,
          modulatedParams: widget.modulatedParams,
          onModulationAssign: widget.onModulationAssign,
        );
    }
  }
}

class _WaveformHeader extends StatelessWidget {
  const _WaveformHeader({
    required this.sampleName,
    required this.showExpandControl,
    required this.onOpenFullscreen,
    this.onCollapse,
  });

  final String sampleName;
  final bool showExpandControl;
  final VoidCallback? onOpenFullscreen;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: showExpandControl ? onOpenFullscreen : null,
      child: Row(
        children: [
          Text(
            'SAMPLER',
            style: theme.textTheme.labelSmall?.copyWith(
              color: SamplerDevicePanel.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sampleName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onCollapse != null)
            IconButton(
              tooltip: 'Collapse device',
              visualDensity: VisualDensity.compact,
              onPressed: onCollapse,
              icon: const Icon(Icons.unfold_less, size: 18, color: Colors.white54),
            ),
          if (showExpandControl)
            IconButton(
              tooltip: 'Open sampler editor',
              visualDensity: VisualDensity.compact,
              onPressed: onOpenFullscreen,
              icon: const Icon(Icons.open_in_full, size: 18, color: Colors.white54),
            ),
        ],
      ),
    );
  }
}

class _SampleTab extends StatelessWidget {
  const _SampleTab({
    required this.peaks,
    required this.showExpandControl,
    required this.onOpenFullscreen,
  });

  final List<double> peaks;
  final bool showExpandControl;
  final VoidCallback? onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: showExpandControl ? onOpenFullscreen : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF121218),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: peaks.isEmpty
              ? Center(
                  child: Text(
                    showExpandControl ? 'Tap to load / trim sample' : 'No sample loaded',
                    style: theme.textTheme.labelMedium?.copyWith(color: Colors.white38),
                  ),
                )
              : CustomPaint(
                  painter: WaveformPainter(peaks: peaks, color: SamplerDevicePanel.wave),
                  child: const SizedBox.expand(),
                ),
        ),
      ),
    );
  }
}

class _EnvTab extends StatelessWidget {
  const _EnvTab({
    required this.device,
    required this.knobSize,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.onModulationAssign,
  });

  final DeviceSnapshot device;
  final double knobSize;
  final void Function(String parameterId, double value) onParameterChanged;
  final Set<String> modulatedParams;
  final void Function(String paramId, String paramLabel)? onModulationAssign;

  @override
  Widget build(BuildContext context) {
    return _KnobRow(
      children: [
        RotaryKnob(
          label: 'Attack',
          value: device.attack,
          size: knobSize,
          displayValue: SamplerDevicePanel.formatPercent(device.attack),
          onChanged: (v) => onParameterChanged('attack', v),
          modulationActive: modulatedParams.contains('attack'),
          onModulationAssign: onModulationAssign != null
              ? () => onModulationAssign!('attack', 'Attack')
              : null,
        ),
        RotaryKnob(
          label: 'Decay',
          value: device.decay,
          size: knobSize,
          displayValue: SamplerDevicePanel.formatPercent(device.decay),
          onChanged: (v) => onParameterChanged('decay', v),
          modulationActive: modulatedParams.contains('decay'),
          onModulationAssign: onModulationAssign != null
              ? () => onModulationAssign!('decay', 'Decay')
              : null,
        ),
        RotaryKnob(
          label: 'Sustain',
          value: device.sustain,
          size: knobSize,
          displayValue: SamplerDevicePanel.formatPercent(device.sustain),
          onChanged: (v) => onParameterChanged('sustain', v),
          modulationActive: modulatedParams.contains('sustain'),
          onModulationAssign: onModulationAssign != null
              ? () => onModulationAssign!('sustain', 'Sustain')
              : null,
        ),
        RotaryKnob(
          label: 'Release',
          value: device.release,
          size: knobSize,
          displayValue: SamplerDevicePanel.formatPercent(device.release),
          onChanged: (v) => onParameterChanged('release', v),
          modulationActive: modulatedParams.contains('release'),
          onModulationAssign: onModulationAssign != null
              ? () => onModulationAssign!('release', 'Release')
              : null,
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.device,
    required this.knobSize,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.onModulationAssign,
  });

  final DeviceSnapshot device;
  final double knobSize;
  final void Function(String parameterId, double value) onParameterChanged;
  final Set<String> modulatedParams;
  final void Function(String paramId, String paramLabel)? onModulationAssign;

  static const _modes = ['LP', 'HP', 'BP', 'NT'];

  @override
  Widget build(BuildContext context) {
    final modeIndex = device.filterMode.clamp(0, _modes.length - 1);

    return Row(
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
              children: List.generate(_modes.length, (index) {
                final selected = index == modeIndex;
                return InkWell(
                  onTap: () => onParameterChanged('filterMode', index.toDouble()),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 36,
                    height: 22,
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
                      _modes[index],
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
              RotaryKnob(
                label: 'Cutoff',
                value: device.filterCutoff,
                size: knobSize,
                displayValue: SamplerDevicePanel.formatCutoffHz(device.filterCutoff),
                onChanged: (v) => onParameterChanged('filterCutoff', v),
                modulationActive: modulatedParams.contains('filterCutoff'),
                onModulationAssign: onModulationAssign != null
                    ? () => onModulationAssign!('filterCutoff', 'Cutoff')
                    : null,
              ),
              RotaryKnob(
                label: 'Resonance',
                value: device.filterQ,
                size: knobSize,
                displayValue: SamplerDevicePanel.formatQ(device.filterQ),
                onChanged: (v) => onParameterChanged('filterQ', v),
                modulationActive: modulatedParams.contains('filterQ'),
                onModulationAssign: onModulationAssign != null
                    ? () => onModulationAssign!('filterQ', 'Resonance')
                    : null,
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

/// Collapsed strip summary — waveform peek + active tab label.
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
            if (!embeddedInCard)
              Container(width: 4, height: double.infinity, color: SamplerDevicePanel.accent),
            if (!embeddedInCard) const SizedBox(width: 10),
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
                            painter: WaveformPainter(peaks: peaks, color: SamplerDevicePanel.wave),
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
