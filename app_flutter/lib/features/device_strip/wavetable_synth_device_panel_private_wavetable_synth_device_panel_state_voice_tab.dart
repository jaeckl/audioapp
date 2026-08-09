part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateVoicetab
    on _WavetableSynthDevicePanelState {
  /// VOICE SVG: dominant Amp ADSR plate (~148) + 3 equal bottom plates (~114).
  Widget _voiceTab() {
    final ampKnob = _knobSize * 1.05;
    final bottomKnob = _knobSize * 0.88;

    return ColoredBox(
      color: const Color(0xFF1A1A24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 55,
              child: _panelBox(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Center(
                  child: _adsrRow(
                    attack: widget.device.attack,
                    decay: widget.device.decay,
                    sustain: widget.device.sustain,
                    release: widget.device.release,
                    spacing: 8,
                    knobSize: ampKnob,
                    labels: const [
                      'ATTACK',
                      'DECAY',
                      'SUSTAIN',
                      'RELEASE'
                    ],
                    onChanged: widget.onParameterChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              flex: 42,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _panelBox(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _knob(
                            label: 'GLIDE',
                            value: widget.device.wtGlide,
                            size: bottomKnob,
                            displayValue:
                                WavetableSynthDevicePanel.formatGlideMs(
                                    widget.device.wtGlide),
                            onChanged: (v) =>
                                widget.onParameterChanged('wtGlide', v),
                            paramId: 'wtGlide',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _panelBox(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _knob(
                            label: 'FEEDBACK',
                            value: widget.device.wtFeedback,
                            size: bottomKnob,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.wtFeedback),
                            onChanged: (v) =>
                                widget.onParameterChanged('wtFeedback', v),
                            paramId: 'wtFeedback',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _panelBox(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _knob(
                            label: 'SPREAD',
                            value: widget.device.wtStereoSpread,
                            size: bottomKnob,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.wtStereoSpread),
                            onChanged: (v) => widget
                                .onParameterChanged('wtStereoSpread', v),
                            paramId: 'wtStereoSpread',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
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
