part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateAdsrrow
    on _SubtractiveSynthDevicePanelState {
  Widget _adsrRow({
    required double attack,
    required double decay,
    required double sustain,
    required double release,
    required void Function(String id, double value) onChanged,
    String prefix = '',
    double? knobScale,
    double spacing = 8,
    double labelGap = 1,
  }) {
    final size = knobScale ?? _knobSize * 0.8;
    String id(String name) => prefix.isEmpty
        ? name
        : '$prefix${name[0].toUpperCase()}${name.substring(1)}';
    final aId = id('attack');
    final dId = id('decay');
    final sId = id('sustain');
    final rId = id('release');
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _knob(
            label: 'A',
            value: attack,
            size: size,
            labelGap: labelGap,
            displayValue: SamplerDevicePanel.formatPercent(attack),
            onChanged: (v) => onChanged(aId, v),
            paramId: aId,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'D',
            value: decay,
            size: size,
            labelGap: labelGap,
            displayValue: SamplerDevicePanel.formatPercent(decay),
            onChanged: (v) => onChanged(dId, v),
            paramId: dId,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'S',
            value: sustain,
            size: size,
            labelGap: labelGap,
            displayValue: SamplerDevicePanel.formatPercent(sustain),
            onChanged: (v) => onChanged(sId, v),
            paramId: sId,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
        SizedBox(width: spacing),
        _knob(
            label: 'R',
            value: release,
            size: size,
            labelGap: labelGap,
            displayValue: SamplerDevicePanel.formatPercent(release),
            onChanged: (v) => onChanged(rId, v),
            paramId: rId,
            modulationAmounts: widget.modulationAmounts,
            connectModeLfoId: widget.connectModeLfoId),
      ],
    );
  }
}
