part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateUnisoncolumn
    on _WavetableSynthDevicePanelState {
  Widget _unisonColumn({
    required double knobScale,
  }) {
    return _panelBox(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'UNISON',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _knob(
                  label: 'Voices',
                  value: widget.device.wtUnison,
                  size: knobScale,
                  labelGap: 1,
                  displayValue: '${1 + (widget.device.wtUnison * 7).round()}',
                  onChanged: (v) => widget.onParameterChanged('wtUnison', v),
                  paramId: 'wtUnison',
                  modulationAmounts: widget.modulationAmounts,
                  connectModeLfoId: widget.connectModeLfoId,
                  onModulationAssign: widget.onModulationAssign,
                ),
              ),
            ),
          ),
          Divider(
            height: 8,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _knob(
                  label: 'Detune',
                  value: widget.device.wtDetune,
                  size: knobScale,
                  labelGap: 1,
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
          ),
        ],
      ),
    );
  }
}
