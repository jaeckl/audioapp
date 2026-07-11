part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateAmptab
    on _SubtractiveSynthDevicePanelState {
  Widget _ampTab() {
    final monoOn = widget.device.synthMono >= 0.5;
    final legatoOn = widget.device.synthLegato >= 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 19,
            child: _panelBox(
              variant: PanelVariant.screen,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DevicePreviewFrame(
                    height: 126,
                    child: SamplerEnvelopePreview(
                      attack: widget.device.attack,
                      decay: widget.device.decay,
                      sustain: widget.device.sustain,
                      release: widget.device.release,
                      accent: SubtractiveSynthDevicePanel.accent,
                      label: '',
                    ),
                  ),
                  const SizedBox(height: 6),
                  _adsrRow(
                    attack: widget.device.attack,
                    decay: widget.device.decay,
                    sustain: widget.device.sustain,
                    release: widget.device.release,
                    onChanged: widget.onParameterChanged,
                    knobScale: _knobSize,
                    spacing: 8,
                    labelGap: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 11,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 144,
                child: _panelBox(
                  variant: PanelVariant.elevated,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  child: Column(
                    children: [
                      const Text('PERFORMANCE',
                          style: DevicePanelTheme.sectionLabel),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _flatToggle(
                              label: monoOn ? 'Mono' : 'Poly',
                              active: monoOn,
                              onTap: () => widget.onParameterChanged(
                                  'synthMono', monoOn ? 0.0 : 1.0),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _flatToggle(
                              label: 'Legato',
                              active: legatoOn,
                              onTap: () => widget.onParameterChanged(
                                  'synthLegato', legatoOn ? 0.0 : 1.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _knob(
                            label: 'Glide',
                            value: widget.device.glideMs,
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
                          _knob(
                            label: 'Velocity',
                            value: widget.device.velocitySensitivity,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.velocitySensitivity),
                            onChanged: (v) => widget.onParameterChanged(
                                'velocitySensitivity', v),
                            paramId: 'velocitySensitivity',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
