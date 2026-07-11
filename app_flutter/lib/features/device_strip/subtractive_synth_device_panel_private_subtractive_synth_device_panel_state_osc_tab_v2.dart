part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateOsctabv2
    on _SubtractiveSynthDevicePanelState {
  Widget _oscTabV2() {
    final knobScale = _knobSize;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 24,
                        child: Row(
                          children: [
                            Expanded(
                              child: _oscSelectorButton(
                                label: 'OSC 1',
                                selected: _selectedOscillator == 0,
                                onTap: () =>
                                    setState(() => _selectedOscillator = 0),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _oscSelectorButton(
                                label: 'OSC 2',
                                selected: _selectedOscillator == 1,
                                onTap: () =>
                                    setState(() => _selectedOscillator = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: _selectedOscillator == 0
                            ? _oscBank(
                                shape: widget.device.osc1Shape,
                                shapeParam: 'osc1Shape',
                                semi: widget.device.osc1Semi,
                                semiParam: 'osc1Semi',
                                octaveNorm: widget.device.osc1Octave,
                                octaveParam: 'osc1Octave',
                                syncValue: widget.device.osc1Sync,
                                syncParam: 'osc1Sync',
                                syncDisplay: SamplerDevicePanel.formatPercent(
                                    widget.device.osc1Sync),
                                detuneValue: widget.device.osc1Detune,
                                detuneParam: 'osc1Detune',
                                detuneDisplay:
                                    '${((widget.device.osc1Detune - 0.5) * 100).round()}¢',
                                knobScale: knobScale,
                              )
                            : _oscBank(
                                shape: widget.device.osc2Shape,
                                shapeParam: 'osc2Shape',
                                semi: widget.device.osc2Semi,
                                semiParam: 'osc2Semi',
                                octaveNorm: widget.device.osc2Octave,
                                octaveParam: 'osc2Octave',
                                syncValue: widget.device.osc2Sync,
                                syncParam: 'osc2Sync',
                                syncDisplay: SamplerDevicePanel.formatPercent(
                                    widget.device.osc2Sync),
                                detuneValue: widget.device.osc2Detune,
                                detuneParam: 'osc2Detune',
                                detuneDisplay:
                                    '${((widget.device.osc2Detune - 0.5) * 100).round()}¢',
                                knobScale: knobScale,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 132,
                  height: 100,
                  child: _panelBox(
                    variant: PanelVariant.elevated,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                    child: Column(
                      children: [
                        const Text('VOICE',
                            style: DevicePanelTheme.sectionLabel),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _knob(
                              label: 'Voices',
                              value: widget.device.unisonVoices,
                              size: 52,
                              labelGap: 0,
                              displayValue:
                                  '${1 + (widget.device.unisonVoices * 3).round()}',
                              onChanged: (v) =>
                                  widget.onParameterChanged('unisonVoices', v),
                              paramId: 'unisonVoices',
                            ),
                            _knob(
                              label: 'Spread',
                              value: widget.device.unisonDetune,
                              size: 52,
                              labelGap: 0,
                              displayValue: SamplerDevicePanel.formatPercent(
                                  widget.device.unisonDetune),
                              onChanged: (v) =>
                                  widget.onParameterChanged('unisonDetune', v),
                              paramId: 'unisonDetune',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          _oscMixerRow(),
        ],
      ),
    );
  }
}
