part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateUnisoncolumn
    on _WavetableSynthDevicePanelState {
  /// SVG bottom-right 152×108 — Voices | Detune, no section title.
  Widget _unisonColumn({required double knobScale}) {
    return _panelBox(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _knob(
                label: 'VOICES',
                value: widget.device.wtUnison,
                size: knobScale,
                labelGap: 2,
                displayValue: '${1 + (widget.device.wtUnison * 7).round()}',
                onChanged: (v) => widget.onParameterChanged('wtUnison', v),
                paramId: 'wtUnison',
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
                label: 'DETUNE',
                value: widget.device.wtDetune,
                size: knobScale,
                labelGap: 2,
                displayValue:
                    SamplerDevicePanel.formatPercent(widget.device.wtDetune),
                onChanged: (v) => widget.onParameterChanged('wtDetune', v),
                paramId: 'wtDetune',
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
