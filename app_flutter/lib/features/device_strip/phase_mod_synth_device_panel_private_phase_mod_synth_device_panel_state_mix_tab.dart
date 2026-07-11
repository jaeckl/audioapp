part of 'phase_mod_synth_device_panel.dart';

extension _PhaseModSynthDevicePanelStateMixtab
    on _PhaseModSynthDevicePanelState {
  Widget _mixTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Master Amp ADSR Envelope
          Expanded(
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Amp Env (Master)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  _adsrRow(
                    prefix: '',
                    a: widget.device.attack,
                    d: widget.device.decay,
                    s: widget.device.sustain,
                    r: widget.device.release,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Row 2: Global Performance (Unison, Spread, Glide, Mono, Legato)
          Expanded(
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _knob(
                    label: 'Unison',
                    value: widget.device.pmUnisonVoices,
                    size: kSize,
                    displayValue:
                        '${(widget.device.pmUnisonVoices * 4).round() + 1}',
                    onChanged: (v) =>
                        widget.onParameterChanged('pmUnisonVoices', v),
                    paramId: 'pmUnisonVoices',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Spread',
                    value: widget.device.pmUnisonDetune,
                    size: kSize,
                    displayValue: SamplerDevicePanel.formatPercent(
                        widget.device.pmUnisonDetune),
                    onChanged: (v) =>
                        widget.onParameterChanged('pmUnisonDetune', v),
                    paramId: 'pmUnisonDetune',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Glide',
                    value: widget.device.pmGlide,
                    size: kSize,
                    displayValue: widget.device.pmGlide <= 0.001
                        ? 'Off'
                        : '${(widget.device.pmGlide * 2000).round()} ms',
                    onChanged: (v) => widget.onParameterChanged('pmGlide', v),
                    paramId: 'pmGlide',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggleKnob(
                        label: '',
                        value: widget.device.pmMono,
                        paramId: 'pmMono',
                        onLabel: 'MONO',
                        offLabel: 'POLY',
                      ),
                      const SizedBox(width: 4),
                      _toggleKnob(
                        label: '',
                        value: widget.device.pmLegato,
                        paramId: 'pmLegato',
                        onLabel: 'LEG',
                        offLabel: 'NORM',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
