import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../sample_library/sample_library_screen.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

/// Layout density for sampler controls.
enum SamplerPanelDensity { strip, editor }

enum SamplerDeviceTab { sample, env, filter, level }

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

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = Color(0xFFE8A54B);
  static const Color wave = Color(0xFF6EC9A0);

  static const _tabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Sample', icon: Icons.graphic_eq),
    DeviceTabSpec(label: 'Env', icon: Icons.show_chart),
    DeviceTabSpec(label: 'Filter', icon: Icons.tune),
    DeviceTabSpec(label: 'Level', icon: Icons.volume_up_outlined),
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

  @override
  State<SamplerDevicePanel> createState() => _SamplerDevicePanelState();
}

class _SamplerDevicePanelState extends State<SamplerDevicePanel> {
  late SamplerDeviceTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleName = widget.sample?.name ?? 'No sample loaded';
    final peaks = widget.sample?.waveformPeaks ?? const <double>[];

    return Material(
      color: SamplerDevicePanel.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
        child: Row(
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
    switch (_tab) {
      case SamplerDeviceTab.sample:
        return _SampleTab(
          peaks: peaks,
          showExpandControl: widget.showExpandControl,
          onOpenFullscreen: widget.onOpenFullscreen,
        );
      case SamplerDeviceTab.env:
        return _EnvTab(
          device: widget.device,
          knobSize: widget._knobSize,
          onParameterChanged: widget.onParameterChanged,
        );
      case SamplerDeviceTab.filter:
        return _FilterTab(
          device: widget.device,
          knobSize: widget._knobSize,
          onParameterChanged: widget.onParameterChanged,
        );
      case SamplerDeviceTab.level:
        return _LevelTab(
          device: widget.device,
          knobSize: widget._knobSize,
          onParameterChanged: widget.onParameterChanged,
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
  });

  final DeviceSnapshot device;
  final double knobSize;
  final void Function(String parameterId, double value) onParameterChanged;

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
        ),
        RotaryKnob(
          label: 'Decay',
          value: device.decay,
          size: knobSize,
          displayValue: SamplerDevicePanel.formatPercent(device.decay),
          onChanged: (v) => onParameterChanged('decay', v),
        ),
        RotaryKnob(
          label: 'Sustain',
          value: device.sustain,
          size: knobSize,
          displayValue: SamplerDevicePanel.formatPercent(device.sustain),
          onChanged: (v) => onParameterChanged('sustain', v),
        ),
        RotaryKnob(
          label: 'Release',
          value: device.release,
          size: knobSize,
          displayValue: SamplerDevicePanel.formatPercent(device.release),
          onChanged: (v) => onParameterChanged('release', v),
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
  });

  final DeviceSnapshot device;
  final double knobSize;
  final void Function(String parameterId, double value) onParameterChanged;

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
              ),
              RotaryKnob(
                label: 'Resonance',
                value: device.filterQ,
                size: knobSize,
                displayValue: SamplerDevicePanel.formatQ(device.filterQ),
                onChanged: (v) => onParameterChanged('filterQ', v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelTab extends StatelessWidget {
  const _LevelTab({
    required this.device,
    required this.knobSize,
    required this.onParameterChanged,
  });

  final DeviceSnapshot device;
  final double knobSize;
  final void Function(String parameterId, double value) onParameterChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotaryKnob(
        label: 'Gain',
        value: device.gain.clamp(0, 1),
        size: knobSize + 8,
        displayValue: SamplerDevicePanel.formatPercent(device.gain.clamp(0, 1)),
        onChanged: (v) => onParameterChanged('gain', v),
      ),
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
    required this.device,
    required this.sample,
    required this.activeTab,
    required this.onExpand,
    required this.onOpenFullscreen,
  });

  final DeviceSnapshot device;
  final SampleLibraryEntrySnapshot? sample;
  final SamplerDeviceTab activeTab;
  final VoidCallback onExpand;
  final VoidCallback onOpenFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peaks = sample?.waveformPeaks ?? const <double>[];
    final tabLabel = SamplerDevicePanel._tabs[activeTab.index].label;

    return Material(
      color: SamplerDevicePanel.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
        child: Row(
          children: [
            Container(width: 4, height: double.infinity, color: SamplerDevicePanel.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'SAMPLER · $tabLabel',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: SamplerDevicePanel.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    sample?.name ?? 'No sample',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF121218),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white12),
                ),
                child: peaks.isEmpty
                    ? null
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CustomPaint(
                          painter: WaveformPainter(peaks: peaks, color: SamplerDevicePanel.wave),
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
            IconButton(
              tooltip: 'Open sampler editor',
              visualDensity: VisualDensity.compact,
              onPressed: onOpenFullscreen,
              icon: const Icon(Icons.open_in_full, size: 18, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
