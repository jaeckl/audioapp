part of 'oscillator_device_panel.dart';

class _OscillatorDevicePanelState extends State<OscillatorDevicePanel> {
  int _tab = 0;

  int get _activeTab => widget.selectedTab?.index ?? _tab;

  @override
  Widget build(BuildContext context) {
    final hz = widget.frequencyHz.round();

    return Material(
      color: widget.embeddedInCard
          ? Colors.transparent
          : OscillatorDevicePanel.panel,
      child: Padding(
        padding: EdgeInsets.fromLTRB(widget.embeddedInCard ? 10 : 0,
            widget.embeddedInCard ? 4 : 6, 10, 6),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
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
                                icon: const Icon(Icons.unfold_less,
                                    size: 18, color: Colors.white54),
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
        child: deviceAutomationKnob(
          label: 'Frequency',
          value: OscillatorDevicePanel._hzToNormalized(widget.frequencyHz),
          size: DeviceKnobSizes.strip + 4,
          displayValue: '$hz Hz',
          onChanged: (v) => widget
              .onFrequencyChanged(OscillatorDevicePanel._normalizedToHz(v)),
          paramId: 'frequency',
          accentColor: OscillatorDevicePanel.accent,
          modulatedParams: widget.modulatedParams,
          automatedParams: widget.automatedParams,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign != null
              ? (_, amount) => widget.onModulationAssign!(amount)
              : null,
          automationLinkActive: widget.automationLinkActive,
          onAutomationLinkTap: widget.onAutomationLinkTap,
          onAutomateParameter: widget.onAutomateParameter,
        ),
      ),
    );
  }
}
