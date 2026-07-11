part of 'bass_synth_device_panel.dart';

extension _BassSynthDevicePanelStateTonetab on _BassSynthDevicePanelState {
  Widget _toneTab() {
    final kSize = _knobSize;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LEFT column: Oscillator + Amp ──
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('OSCILLATOR'),
                  Expanded(
                    flex: 5,
                    child: _panelBox(
                      color: const Color(0xFF16161E),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _knob(
                            label: 'Morph',
                            value: widget.device.bassOscShape,
                            size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.bassOscShape),
                            onChanged: (v) =>
                                widget.onParameterChanged('bassOscShape', v),
                            paramId: 'bassOscShape',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(
                            label: 'Sub Mix',
                            value: widget.device.bassSubMix,
                            size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.bassSubMix),
                            onChanged: (v) =>
                                widget.onParameterChanged('bassSubMix', v),
                            paramId: 'bassSubMix',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _intOctaveSlot(
                            value: widget.device.bassSubOctave,
                            paramId: 'bassSubOctave',
                            min: 0,
                            max: 2,
                            label: 'Sub',
                            formatter: BassSynthDevicePanel.subOctaveLabel,
                          ),
                          _intOctaveSlot(
                            value: widget.device.bassOctave,
                            paramId: 'bassOctave',
                            min: 0,
                            max: 4,
                            label: 'Oct',
                            formatter: BassSynthDevicePanel.bassOctaveLabel,
                          ),
                          _knob(
                            label: 'Noise',
                            value: widget.device.bassNoise,
                            size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.bassNoise),
                            onChanged: (v) =>
                                widget.onParameterChanged('bassNoise', v),
                            paramId: 'bassNoise',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _sectionLabel('AMP'),
                  Expanded(
                    flex: 4,
                    child: _panelBox(
                      color: const Color(0xFF1A1A24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(2, 2, 6, 2),
                              child: _ampEnvelopePreview(),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _knob(
                                    label: 'A',
                                    value: widget.device.attack,
                                    size: kSize,
                                    labelGap: 0,
                                    displayValue:
                                        SamplerDevicePanel.formatPercent(
                                            widget.device.attack),
                                    onChanged: (v) =>
                                        widget.onParameterChanged('attack', v),
                                    paramId: 'attack',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                  _knob(
                                    label: 'S',
                                    value: widget.device.sustain,
                                    size: kSize,
                                    labelGap: 0,
                                    displayValue:
                                        SamplerDevicePanel.formatPercent(
                                            widget.device.sustain),
                                    onChanged: (v) =>
                                        widget.onParameterChanged('sustain', v),
                                    paramId: 'sustain',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                  _knob(
                                    label: 'R',
                                    value: widget.device.release,
                                    size: kSize,
                                    labelGap: 0,
                                    displayValue:
                                        SamplerDevicePanel.formatPercent(
                                            widget.device.release),
                                    onChanged: (v) =>
                                        widget.onParameterChanged('release', v),
                                    paramId: 'release',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── RIGHT column: PERFORMANCE (Glide + Vel) ──
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('PERFORMANCE'),
                Expanded(
                  child: _panelBox(
                    color: const Color(0xFF16161E),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _knob(
                          label: 'Glide',
                          value: widget.device.glideMs,
                          size: kSize,
                          displayValue: widget.device.glideMs <= 0.001
                              ? 'Off'
                              : '${(widget.device.glideMs * 2000).round()} ms',
                          onChanged: (v) =>
                              widget.onParameterChanged('glideMs', v),
                          paramId: 'glideMs',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                        const SizedBox(height: 12),
                        _knob(
                          label: 'Vel',
                          value: widget.device.bassVelocitySense,
                          size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(
                              widget.device.bassVelocitySense),
                          onChanged: (v) =>
                              widget.onParameterChanged('bassVelocitySense', v),
                          paramId: 'bassVelocitySense',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
