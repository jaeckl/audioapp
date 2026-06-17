import 'package:flutter/material.dart';

import 'device_knob_sizes.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

enum OscillatorDeviceTab { tone }

/// Tabbed oscillator device — big frequency knob on Tone tab.
class OscillatorDevicePanel extends StatefulWidget {
  const OscillatorDevicePanel({
    super.key,
    required this.trackName,
    required this.frequencyHz,
    required this.onFrequencyChanged,
    this.onCollapse,
  });

  final String trackName;
  final double frequencyHz;
  final ValueChanged<double> onFrequencyChanged;
  final VoidCallback? onCollapse;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = Color(0xFF6EC9E8);

  static const _tabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Tone', icon: Icons.waves),
  ];

  static double _hzToNormalized(double hz) {
    const minHz = 110.0;
    const maxHz = 880.0;
    return ((hz - minHz) / (maxHz - minHz)).clamp(0.0, 1.0);
  }

  static double _normalizedToHz(double normalized) {
    const minHz = 110.0;
    const maxHz = 880.0;
    return minHz + normalized.clamp(0, 1) * (maxHz - minHz);
  }

  @override
  State<OscillatorDevicePanel> createState() => _OscillatorDevicePanelState();
}

class _OscillatorDevicePanelState extends State<OscillatorDevicePanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hz = widget.frequencyHz.round();

    return Material(
      color: OscillatorDevicePanel.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: OscillatorDevicePanel.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'OSCILLATOR',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: OscillatorDevicePanel.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.trackName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.onCollapse != null)
                        IconButton(
                          tooltip: 'Collapse device',
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onCollapse,
                          icon: const Icon(Icons.unfold_less, size: 18, color: Colors.white54),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DeviceTabBar(
                    tabs: OscillatorDevicePanel._tabs,
                    selectedIndex: _tab,
                    onSelected: (index) => setState(() => _tab = index),
                    accentColor: OscillatorDevicePanel.accent,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF121218),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Center(
                        child: RotaryKnob(
                          label: 'Frequency',
                          value: OscillatorDevicePanel._hzToNormalized(widget.frequencyHz),
                          size: DeviceKnobSizes.strip + 4,
                          displayValue: '$hz Hz',
                          accentColor: OscillatorDevicePanel.accent,
                          onChanged: (v) =>
                              widget.onFrequencyChanged(OscillatorDevicePanel._normalizedToHz(v)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OscillatorDeviceStripCollapsed extends StatelessWidget {
  const OscillatorDeviceStripCollapsed({
    super.key,
    required this.trackName,
    required this.frequencyHz,
    required this.onExpand,
  });

  final String trackName;
  final double frequencyHz;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: OscillatorDevicePanel.panel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
        child: Row(
          children: [
            Container(width: 4, height: double.infinity, color: OscillatorDevicePanel.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OSCILLATOR · Tone',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: OscillatorDevicePanel.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$trackName · ${frequencyHz.round()} Hz',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Expand device',
              onPressed: onExpand,
              icon: const Icon(Icons.unfold_more, size: 20, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
