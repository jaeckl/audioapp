part of 'phase_mod_synth_device_panel.dart';

extension _PhaseModSynthDevicePanelStateAdsrrow
    on _PhaseModSynthDevicePanelState {
  Widget _adsrRow({
    required String prefix,
    required double a,
    required double d,
    required double s,
    required double r,
  }) {
    final kSize = _knobSize;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _knob(
          label: 'A',
          value: a,
          size: kSize,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(a),
          onChanged: (v) => widget.onParameterChanged(
              prefix.isEmpty ? 'attack' : '${prefix}Attack', v),
          paramId: '${prefix}Attack',
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'D',
          value: d,
          size: kSize,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(d),
          onChanged: (v) => widget.onParameterChanged(
              prefix.isEmpty ? 'decay' : '${prefix}Decay', v),
          paramId: '${prefix}Decay',
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'S',
          value: s,
          size: kSize,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(s),
          onChanged: (v) => widget.onParameterChanged(
              prefix.isEmpty ? 'sustain' : '${prefix}Sustain', v),
          paramId: '${prefix}Sustain',
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
        _knob(
          label: 'R',
          value: r,
          size: kSize,
          labelGap: 0,
          displayValue: SamplerDevicePanel.formatPercent(r),
          onChanged: (v) => widget.onParameterChanged(
              prefix.isEmpty ? 'release' : '${prefix}Release', v),
          paramId: '${prefix}Release',
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
        ),
      ],
    );
  }
}
