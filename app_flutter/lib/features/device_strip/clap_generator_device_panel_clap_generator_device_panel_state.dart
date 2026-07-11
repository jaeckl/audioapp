part of 'clap_generator_device_panel.dart';

class _ClapGeneratorDevicePanelState extends State<ClapGeneratorDevicePanel> {
  late ClapDeviceTab _tab;

  ClapDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  @override
  void initState() {
    super.initState();
    _tab = ClapDeviceTab.burst;
  }

  Widget _knob({
    required String label,
    required double value,
    required String paramId,
    required ValueChanged<double> onChanged,
    String? displayValue,
  }) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: DeviceKnobSizes.strip,
      displayValue: displayValue,
      accentColor: ClapGeneratorDevicePanel.accent,
      modulationActive: widget.modulatedParams.contains(paramId),
      automationActive: widget.automatedParams.contains(paramId),
      modulationAmount: widget.modulationAmounts[paramId] ?? 0.0,
      connectModeActive: widget.connectModeLfoId != null,
      onModulationAssign: widget.onModulationAssign != null
          ? (amount) => widget.onModulationAssign!(paramId, amount)
          : null,
      linkModeActive: widget.automationLinkActive,
      onLinkTap: widget.onAutomationLinkTap != null
          ? () => widget.onAutomationLinkTap!(paramId)
          : null,
      onAutomateRequest: widget.onAutomateParameter != null
          ? () => widget.onAutomateParameter!(paramId)
          : null,
      onChanged: onChanged,
    );
  }

  Widget _previewBox({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: child),
    );
  }

  Widget _preview() {
    return ClapBurstPreview(
      bursts: widget.device.clapBursts,
      spread: widget.device.clapSpread,
      decay: widget.device.clapDecay,
      accent: ClapGeneratorDevicePanel.accent,
    );
  }

  Widget _burstTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(flex: 3, child: _previewBox(child: _preview())),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _knob(
                  label: 'Bursts',
                  value: widget.device.clapBursts,
                  paramId: 'clapBursts',
                  displayValue: clapBurstsLabel(widget.device.clapBursts),
                  onChanged: (v) => widget.onParameterChanged('clapBursts', v),
                ),
                _knob(
                  label: 'Spread',
                  value: widget.device.clapSpread,
                  paramId: 'clapSpread',
                  displayValue: '${(widget.device.clapSpread * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('clapSpread', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toneTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _knob(
            label: 'Tone',
            value: widget.device.clapTone,
            paramId: 'clapTone',
            displayValue: '${(widget.device.clapTone * 100).round()}%',
            onChanged: (v) => widget.onParameterChanged('clapTone', v),
          ),
          _knob(
            label: 'Room',
            value: widget.device.clapRoom,
            paramId: 'clapRoom',
            displayValue: '${(widget.device.clapRoom * 100).round()}%',
            onChanged: (v) => widget.onParameterChanged('clapRoom', v),
          ),
        ],
      ),
    );
  }

  Widget _ampTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _knob(
        label: 'Decay',
        value: widget.device.clapDecay,
        paramId: 'clapDecay',
        displayValue: clapDecayLabel(widget.device.clapDecay),
        onChanged: (v) => widget.onParameterChanged('clapDecay', v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabBody = switch (_activeTab) {
      ClapDeviceTab.burst => _burstTab(),
      ClapDeviceTab.tone => _toneTab(),
      ClapDeviceTab.amp => _ampTab(),
    };

    if (widget.embeddedInCard) {
      return tabBody;
    }

    return Material(
      color: const Color(0xFF1C1C24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              'CLAP GENERATOR',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(child: tabBody),
        ],
      ),
    );
  }
}
