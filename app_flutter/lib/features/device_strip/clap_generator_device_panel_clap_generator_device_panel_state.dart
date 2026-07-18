part of 'clap_generator_device_panel.dart';

class _ClapGeneratorDevicePanelState extends State<ClapGeneratorDevicePanel> {
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
      parameterId: paramId,
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

  Widget _pitchControl() {
    final active = widget.device.clapKeyTrack >= 0.5;
    return PercussionPitchControl(
      active: active,
      accent: ClapGeneratorDevicePanel.accent,
      knob: _knob(
        label: active ? 'Tune' : 'Pitch',
        value: widget.device.clapPitch,
        paramId: 'clapPitch',
        displayValue: percussionPitchLabel(widget.device.clapPitch),
        onChanged: (value) => widget.onParameterChanged('clapPitch', value),
      ),
      onChanged: (enabled) => widget.onParameterChanged(
        'clapKeyTrack',
        enabled ? 1.0 : 0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bench = PercussionPanelLayout(
      flexes: const [5, 6],
      cards: [
        PercussionControlCard(
          child: Column(
            children: [
              PercussionMiniPreview(
                child: ClapBurstPreview(
                  bursts: widget.device.clapBursts,
                  spread: widget.device.clapSpread,
                  decay: widget.device.clapDecay,
                  accent: ClapGeneratorDevicePanel.accent,
                ),
              ),
              Expanded(child: Center(child: _pitchControl())),
            ],
          ),
        ),
        PercussionControlCard(
          child: PercussionKnobRows(
            rows: [
              [
                _knob(
                  label: 'Bursts',
                  value: widget.device.clapBursts,
                  paramId: 'clapBursts',
                  displayValue: clapBurstsLabel(widget.device.clapBursts),
                  onChanged: (value) =>
                      widget.onParameterChanged('clapBursts', value),
                ),
                _knob(
                  label: 'Spread',
                  value: widget.device.clapSpread,
                  paramId: 'clapSpread',
                  displayValue: '${(widget.device.clapSpread * 100).round()}%',
                  onChanged: (value) =>
                      widget.onParameterChanged('clapSpread', value),
                ),
                _knob(
                  label: 'Tone',
                  value: widget.device.clapTone,
                  paramId: 'clapTone',
                  displayValue: '${(widget.device.clapTone * 100).round()}%',
                  onChanged: (value) =>
                      widget.onParameterChanged('clapTone', value),
                ),
              ],
              [
                _knob(
                  label: 'Room',
                  value: widget.device.clapRoom,
                  paramId: 'clapRoom',
                  displayValue: '${(widget.device.clapRoom * 100).round()}%',
                  onChanged: (value) =>
                      widget.onParameterChanged('clapRoom', value),
                ),
                _knob(
                  label: 'Decay',
                  value: widget.device.clapDecay,
                  paramId: 'clapDecay',
                  displayValue: clapDecayLabel(widget.device.clapDecay),
                  onChanged: (value) =>
                      widget.onParameterChanged('clapDecay', value),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return PercussionPanelSurface(
      title: 'CLAP GENERATOR',
      embeddedInCard: widget.embeddedInCard,
      child: bench,
    );
  }
}
