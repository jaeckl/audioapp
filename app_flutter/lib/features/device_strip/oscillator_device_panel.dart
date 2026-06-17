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
    this.embeddedInCard = false,
    this.selectedTab,
  });

  final String trackName;
  final double frequencyHz;
  final ValueChanged<double> onFrequencyChanged;
  final VoidCallback? onCollapse;
  final bool embeddedInCard;
  final OscillatorDeviceTab? selectedTab;

  static const Color panel = Color(0xFF1C1C24);
  static const Color accent = Color(0xFF6EC9E8);

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Tone', icon: Icons.waves),
  ];

  static const _tabs = containerTabs;

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

  int get _activeTab => widget.selectedTab?.index ?? _tab;

  @override
  Widget build(BuildContext context) {
    final hz = widget.frequencyHz.round();

    return Material(
      color: widget.embeddedInCard ? Colors.transparent : OscillatorDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(widget.embeddedInCard ? 10 : 0, widget.embeddedInCard ? 4 : 6, 10, 6),
        child: widget.embeddedInCard
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _toneKnob(hz)),
                ],
              )
            : Row(
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
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                          selectedIndex: _activeTab,
                          onSelected: (index) => setState(() => _tab = index),
                          accentColor: OscillatorDevicePanel.accent,
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: _toneKnob(hz)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _toneKnob(int hz) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121218),
        borderRadius: BorderRadius.circular(2),
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
    );
  }
}

class OscillatorDeviceStripCollapsed extends StatelessWidget {
  const OscillatorDeviceStripCollapsed({
    super.key,
    required this.onExpand,
    this.embeddedInCard = false,
  });

  final VoidCallback onExpand;
  final bool embeddedInCard;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: embeddedInCard ? Colors.transparent : OscillatorDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(embeddedInCard ? 10 : 0, 4, 8, 4),
        child: Row(
          children: [
            if (!embeddedInCard)
              Container(width: 4, height: double.infinity, color: OscillatorDevicePanel.accent),
            if (!embeddedInCard) const SizedBox(width: 10),
            const Spacer(),
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
