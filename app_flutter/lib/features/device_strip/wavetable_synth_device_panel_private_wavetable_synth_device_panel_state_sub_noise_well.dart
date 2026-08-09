part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateSubnoisewell
    on _WavetableSynthDevicePanelState {
  /// SVG bottom-left: 108-wide shape group over Sub+Oct; Noise|Color right.
  Widget _subNoiseWell({required double knobScale}) {
    return _panelBox(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  height: DevicePanelTheme.modeRowHeight,
                  child: _subShapeRow(),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _knob(
                            label: 'SUB',
                            value: widget.device.wtSubLevel,
                            size: knobScale,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.wtSubLevel),
                            onChanged: (v) =>
                                widget.onParameterChanged('wtSubLevel', v),
                            paramId: 'wtSubLevel',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                        ),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _subOctaveSlot(
                            value: widget.device.wtSubOctave,
                            knobScale: knobScale * 0.85,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _knob(
                      label: 'NOISE',
                      value: widget.device.wtNoiseLevel,
                      size: knobScale,
                      displayValue: SamplerDevicePanel.formatPercent(
                          widget.device.wtNoiseLevel),
                      onChanged: (v) =>
                          widget.onParameterChanged('wtNoiseLevel', v),
                      paramId: 'wtNoiseLevel',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _knob(
                      label: 'COLOR',
                      value: widget.device.wtNoiseColor,
                      size: knobScale,
                      displayValue: SamplerDevicePanel.formatPercent(
                          widget.device.wtNoiseColor),
                      onChanged: (v) =>
                          widget.onParameterChanged('wtNoiseColor', v),
                      paramId: 'wtNoiseColor',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
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
