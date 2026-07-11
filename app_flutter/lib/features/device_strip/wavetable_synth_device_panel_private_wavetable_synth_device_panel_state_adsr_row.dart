part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateAdsrrow
    on _WavetableSynthDevicePanelState {
  Widget _adsrRow({
    required double attack,
    required double decay,
    required double sustain,
    required double release,
    required void Function(String id, double value) onChanged,
    String prefix = '',
    double spacing = 6,
  }) {
    final size = _knobSize * 0.78;
    String id(String n) =>
        prefix.isEmpty ? n : '$prefix${n[0].toUpperCase()}${n.substring(1)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _knob(
            label: 'A',
            value: attack,
            size: size,
            labelGap: 1,
            displayValue: SamplerDevicePanel.formatPercent(attack),
            onChanged: (v) => onChanged(id('attack'), v),
            paramId: id('attack'),
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'D',
            value: decay,
            size: size,
            labelGap: 1,
            displayValue: SamplerDevicePanel.formatPercent(decay),
            onChanged: (v) => onChanged(id('decay'), v),
            paramId: id('decay'),
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'S',
            value: sustain,
            size: size,
            labelGap: 1,
            displayValue: SamplerDevicePanel.formatPercent(sustain),
            onChanged: (v) => onChanged(id('sustain'), v),
            paramId: id('sustain'),
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'R',
            value: release,
            size: size,
            labelGap: 1,
            displayValue: SamplerDevicePanel.formatPercent(release),
            onChanged: (v) => onChanged(id('release'), v),
            paramId: id('release'),
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
      ],
    );
  }
}
