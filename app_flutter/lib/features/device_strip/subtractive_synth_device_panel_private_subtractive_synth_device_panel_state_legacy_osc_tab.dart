part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateLegacyosctab
    on _SubtractiveSynthDevicePanelState {
  Widget _legacyOscTab() {
    final knobScale = _knobSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 10,
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
                          onTap: () => setState(() => _selectedOscillator = 0),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _oscSelectorButton(
                          label: 'OSC 2',
                          selected: _selectedOscillator == 1,
                          onTap: () => setState(() => _selectedOscillator = 1),
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
                const SizedBox(height: 4),
                _oscMixerRow(),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: _panelBox(
              variant: PanelVariant.elevated,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              child: Column(
                children: [
                  const Text('VOICE', style: DevicePanelTheme.sectionLabel),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _knob(
                        label: 'Voices',
                        value: widget.device.unisonVoices,
                        size: 44,
                        displayValue:
                            '${1 + (widget.device.unisonVoices * 3).round()}',
                        onChanged: (v) =>
                            widget.onParameterChanged('unisonVoices', v),
                        paramId: 'unisonVoices',
                      ),
                      _knob(
                        label: 'Spread',
                        value: widget.device.unisonDetune,
                        size: 44,
                        displayValue: SamplerDevicePanel.formatPercent(
                            widget.device.unisonDetune),
                        onChanged: (v) =>
                            widget.onParameterChanged('unisonDetune', v),
                        paramId: 'unisonDetune',
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _knob(
                        label: 'Pitch',
                        value: widget.device.globalPitch,
                        size: 44,
                        displayValue:
                            SubtractiveSynthDevicePanel.formatGlobalPitch(
                                widget.device.globalPitch),
                        onChanged: (v) =>
                            widget.onParameterChanged('globalPitch', v),
                        paramId: 'globalPitch',
                      ),
                      _knob(
                        label: 'Feedback',
                        value: widget.device.mixFeedback,
                        size: 44,
                        displayValue: SamplerDevicePanel.formatPercent(
                            widget.device.mixFeedback),
                        onChanged: (v) =>
                            widget.onParameterChanged('mixFeedback', v),
                        paramId: 'mixFeedback',
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
